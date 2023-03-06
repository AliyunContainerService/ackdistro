#!/bin/bash

#------------------------------------------------------------------------------------
# Program:
#   1. install containerd/containerd-shim/runc/nerdctl/crictl/ctr/cni ... etc.
#   2. install containerd.service
#   3. install config.toml
# History:
#   2021/06/10  muze.gxc    First release
#   2021/06/28  muze.gxc    bugfix: fix the case that containerd exists
#   2021/07/12  muze.gxc    bugfix: add the cgroup driver choice to the config.toml
#   2022/07/22  DanteCui    move into ack-distro
#------------------------------------------------------------------------------------

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -e;set -x
if public::nvidia::check_has_gpu ${scripts_path};then
  bash "${scripts_path}"/docker.sh
  exit 0
fi

# get params
storage=${ContainerDataRoot:-/var/lib/containerd} # containerd default uses /var/lib/containerd
mkdir -p $storage

# Begin install containerd
if ! containerd --version; then
  lsb_dist=$(utils_get_distribution)
  lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
  echo "current system is ${lsb_dist}"

  # containerd bin、crictl bin、ctr bin、nerdctr bin、cni plugin etc
  tar -zxvf "${scripts_path}"/../tgz/containerd.tgz -C /
  chmod a+x /usr/local/bin
  chmod a+x /usr/local/sbin

  case "${lsb_dist}" in
  ubuntu | deepin | debian | raspbian)
    cp -f "${scripts_path}"/../etc/containerd.service /etc/systemd/system/containerd.service
    if [ ! -f /usr/sbin/iptables ];then
      if [ -f /sbin/iptables ];then
        ln -s /sbin/iptables /usr/sbin/iptables
      else
        echo "iptables not found, please check"
        exit 1
      fi
    fi
    ;;
  centos | rhel | anolis | ol | sles | kylin | neokylin)
    RPM_DIR=${scripts_path}/../rpm/
    rpm=libseccomp
    if ! rpm -qa | grep ${rpm};then
      rpm -ivh --force --nodeps ${RPM_DIR}/${rpm}*.rpm
    fi
    cp -f "${scripts_path}"/../etc/containerd.service /etc/systemd/system/containerd.service
    ;;
  alios)
    docker0=$(ip addr show docker0 | head -1|tr " " "\n"|grep "<"|grep -iwo "UP"|wc -l)
    if [ "$docker0" != "1" ]; then
        ip link add name docker0 type bridge
        ip addr add dev docker0 172.17.0.1/16
    fi
    RPM_DIR=${scripts_path}/../rpm/
    rpm=libseccomp
    if ! rpm -qa | grep ${rpm};then
      rpm -ivh --force --nodeps ${RPM_DIR}/${rpm}*.rpm
    fi
    cp -f "${scripts_path}"/../etc/containerd.service /etc/systemd/system/containerd.service
    ;;
  *)
    utils_error "unknown system to use /etc/systemd/system/containerd.service"
    cp -f "${scripts_path}"/../etc/containerd.service /etc/systemd/system/containerd.service
    ;;
  esac

  # install /etc/containerd/config.toml
  mkdir -p /etc/containerd
  cp -f ${scripts_path}/../etc/containerd-config.toml /etc/containerd/config.toml
fi

LocalRegistryPort=${LocalRegistryPort:-5000}
mkdir -p /etc/containerd/certs.d

mkdir -p /etc/containerd/certs.d/docker.io
cat > /etc/containerd/certs.d/docker.io/hosts.toml <<EOF
server = "https://registry-1.docker.io"
EOF

mkRegistryHostToml() {
  mkdir -p /etc/containerd/certs.d/${1}
  cat > /etc/containerd/certs.d/${1}/hosts.toml <<EOF
server = "https://${1}"
[host."https://${1}"]
  skip_verify = true
EOF
}

mkRegistryHostToml 127.0.0.1:${LocalRegistryPort}
mkRegistryHostToml sea.hub:${LocalRegistryPort}
mkRegistryHostToml registry-internal.adp.aliyuncs.com:${LocalRegistryPort}
mkRegistryHostToml ack-agility-registry.cn-shanghai.cr.aliyuncs.com
mkRegistryHostToml 127.0.0.1:${LocalRegistryPort}
if [ "${TrustedRegistry}" != "" ];then
  mkRegistryHostToml ${TrustedRegistry}
fi

harborURL=""
if [ "${harborAddress}" != "" ];then
  harborURL=${harborAddress}
elif [ "${gatewayDomain}" != "" ];then
  harborURL=harbor.${gatewayDomain}
else
  harborURL=harbor.cnstack.local
fi
mkRegistryHostToml ${harborURL}

disable_selinux
systemctl daemon-reload
systemctl enable containerd.service
systemctl restart containerd.service

mkdir -p /etc/sealer-cri/
echo -n "/run/containerd/containerd.sock" > /etc/sealer-cri/socket-path