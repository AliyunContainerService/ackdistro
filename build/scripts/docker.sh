#!/bin/bash
# Copyright © 2021 Alibaba Group Holding Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -x

DOCKER_VERSION="19.03.15"

check_docker_valid() {
  if ! docker info 2>&1; then
    panic "docker is not healthy: $(docker info 2>&1), please check"
  fi

  dockerVersion=`docker info --format '{{json .ServerVersion}}' | tr -d '"'`
  if [ "${dockerVersion}" != "${DOCKER_VERSION}" ]; then
    panic "docker version is ${dockerVersion}, should be 19.03.15, please check"
  fi
}

storage=${ContainerDataRoot:-/var/lib/docker}
mkdir -p $storage
if ! utils_command_exists docker; then
  lsb_dist=$(utils_get_distribution)
  lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
  echo "current system is ${lsb_dist}"
  case "${lsb_dist}" in
  ubuntu | deepin | debian | raspbian)
    cp -f "${scripts_path}"/../etc/docker.service /lib/systemd/system/docker.service
    if [ ! -f /usr/sbin/iptables ];then
      if [ -f /sbin/iptables ];then
        ln -s /sbin/iptables /usr/sbin/iptables
      else
        panic "iptables not found, please check"
      fi
    fi
    ;;
  centos | rhel | anolis | ol | sles | kylin | neokylin)
    RPM_DIR=${scripts_path}/../rpm/
    rpm=libseccomp
    if ! rpm -qa | grep ${rpm};then
      rpm -ivh --force --nodeps ${RPM_DIR}/${rpm}*.rpm
    fi
    cp -f "${scripts_path}"/../etc/docker.service /usr/lib/systemd/system/docker.service
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
    cp "${scripts_path}"/../etc/docker.service /usr/lib/systemd/system/docker.service
    ;;
  *)
    utils_info "unknown system to use /lib/systemd/system/docker.service"
    cp "${scripts_path}"/../etc/docker.service /lib/systemd/system/docker.service
    ;;
  esac

  [ -d /etc/docker/ ] || mkdir /etc/docker/ -p

  chmod -R 755 "${scripts_path}"/../cri
  tar -zxvf "${scripts_path}"/../cri/docker.tar.gz -C /usr/bin
  chmod a+x /usr/bin
  chmod a+x /usr/bin/docker
  chmod a+x /usr/bin/dockerd
  systemctl enable docker.service
  cp "${scripts_path}"/../etc/daemon.json /etc/docker
  systemctl restart docker.service
  mkdir -p /root/.docker/
  cp "${scripts_path}"/../etc/docker-cli-config.json /root/.docker/config.json
  docker0=$(ip addr show docker0 | head -1|tr " " "\n"|grep "<"|grep -iwo "UP"|wc -l)
  if [ "$docker0" != "1" ]; then
      ip link add name docker0 type bridge
      ip addr add dev docker0 172.17.0.1/16
  fi
fi

disable_selinux
systemctl daemon-reload
systemctl restart docker.service
check_docker_valid

mkdir -p /etc/sealerio/cri/
echo "/var/run/dockershim.sock" > /etc/sealerio/cri/socket-path