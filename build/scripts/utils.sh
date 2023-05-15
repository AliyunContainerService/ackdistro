#!/bin/bash

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
export defaultVgName="ackdistro-pool"
export extraMountPointAnno="#ackdistro-extra-mountpoint"
export extraLVNamePrefix="ackdistro-extra-lv"

utils_version_ge() {
  test "$(echo "$@" | tr ' ' '\n' | sort -rV | head -n 1)" == "$1"
}

# This function will display the message in red, and exit immediately.
panic()
{
    set +x
    echo -e "\033[1;31mPanic error: $@, please check this panic\033[0m"
    exit 1
    set -x
}

utils_info()
{
    echo -e "\033[1;32m$@\033[0m"
}

utils_command_exists() {
    command -v "$@" > /dev/null 2>&1
}

utils_arch_env() {
    ARCH=$(uname -m)
    case $ARCH in
        armv5*) ARCH="armv5" ;;
        armv6*) ARCH="armv6" ;;
        armv7*) ARCH="armv7" ;;
        aarch64) ARCH="arm64" ;;
        x86) ARCH="386" ;;
        x86_64) ARCH="amd64" ;;
        i686) ARCH="386" ;;
        i386) ARCH="386" ;;
    esac
}

utils_os_env() {
    ubu=$(cat /etc/issue | grep -i "ubuntu" | wc -l)
    debian=$(cat /etc/issue | grep -i "debian" | wc -l)
    cet=$(cat /etc/centos-release | grep "CentOS" | wc -l)
    redhat=$(cat /etc/redhat-release | grep "Red Hat" | wc -l)
    alios=$(cat /etc/redhat-release | grep "Alibaba" | wc -l)
    kylin=$(cat /etc/kylin-release | grep -E "Kylin" | wc -l)
    anolis=$(cat /etc/anolis-release | grep -E "Anolis" | wc -l)
    if [ "$ubu" == "1" ];then
        export OS="Ubuntu"
    elif [ "$cet" == "1" ];then
        export OS="CentOS"
    elif [ "$redhat" == "1" ];then
        export OS="RedHat"
    elif [ "$debian" == "1" ];then
        export OS="Debian"
    elif [ "$alios" == "1" ];then
        export OS="AliOS"
    elif [ "$kylin" == "1" ];then
        export OS="Kylin"
    elif [ "$anolis" == 1 ];then
        export OS="Anolis"
    else
       echo "unkown os..."
    fi

    case "$OS" in
        CentOS)
            export OSVersion="$(cat /etc/centos-release | awk '{print $4}')"
            ;;
        AliOS)
            export OSVersion="$(cat /etc/alios-release | awk '{print $7}')"
            ;;
        Kylin)
            export OSVersion="$(cat /etc/kylin-release | awk '{print $6}')"
            ;;
        Anolis)
            export OSVersion="$(cat /etc/anolis-release | awk '{print $4}')"
            ;;
        RedHat)
            export OSVersion=`utils_get_redhat_release`
            ;;
        *)
            echo -e "Not support get OS version of ${OS}"
    esac

    if [[ "$OS" == "CentOS" ]] || [[ "$OS" == "Anolis" ]] || [[ "$OS" == "AliOS" ]] || [[ "$OS" == "RedHat" ]];then
        export OSRelease="el7"
        # vague compare: 8.x.xxx
        if [[ $OSVersion =~ ^8\..*$ ]];then
            export OSRelease="el8"
        fi
    fi
}

utils_get_distribution() {
  lsb_dist=""
  # Every system that we officially support has /etc/os-release
  if [ -r /etc/os-release ]; then
    lsb_dist="$(. /etc/os-release && echo "$ID")"
  fi
  # Returning an empty string here should be alright since the
  # case statements don't act unless you provide an actual value
  echo "$lsb_dist"
}

utils_get_redhat_release() {
  redhat_release=""
  if [ -r /etc/os-release ]; then
    redhat_release="$(. /etc/os-release && echo "$VERSION_ID")"
  fi
  echo "$redhat_release"
}

utils_no_need_mkfs() {
  if [[ "$1" == "" ]] || [[ "$1" == "/" ]] || [[ "$1" == "\"/\"" ]];then
    return 0
  fi

  return 1
}

utils_split_str_to_array() {
  NEW_IFS=","
  if echo ${1} | grep "&" &>/dev/null;then
     NEW_IFS="&"
  fi
  OLD_IFS="$IFS"
  IFS=${NEW_IFS}
  for i in $1;do
    echo $i
  done
  IFS="$OLD_IFS"
}

utils_is_device_array() {
  utils_no_need_mkfs $1 && return 1

  # check each dev name
  for temp in `utils_split_str_to_array $1`;do
    if [[ $temp =~ "/dev" ]];then
      continue
    else
      return 1
    fi
  done

  return 0
}

utils_is_vgname() {
  utils_no_need_mkfs $1 && return 1
  utils_is_device_array $1 && return 1

  return 0
}

disable_selinux() {
  if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
  fi
}

public::nvidia::check(){
    if [ "$ARCH" != "amd64" ];then
        utils_info "gpu now not support $ARCH"
        return 1
    fi
    if which nvidia-smi;then
        return 0
    fi

    return 1
}

kube::nvidia::setup_lspci(){
    if utils_command_exists lspci; then
        return
    fi
    utils_info "lspci command not exist, install it"
    rpm -ivh --force --nodeps ${1}/../rpm/nvidia/pciutils*.rpm
    if [[ "$?" != "0" ]]; then
        panic "failed to install pciutils via command (rpm -ivh --force --nodeps ${1}/../rpm/nvidia/pciutils*.rpm) in dir ${PWD}, please run it for debug"
    fi
}

kube::nvidia::detect_gpu(){
    tar -xvf ${1}/../tgz/nvidia.tgz -C ${1}/../rpm/
    kube::nvidia::setup_lspci ${1}
    lspci | grep -i nvidia > /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        return 0
    fi
    return 1
}

public::nvidia::check_has_gpu(){
    utils_arch_env
    if ! public::nvidia::check;then
        return 1
    fi

    if ! kube::nvidia::detect_gpu ${1};then
        return 1
    fi

    return 0
}

process_taints_labels() {
  local RemoveMasterTaint=$1
  local PlatformType=$2

  # process taints first
  if [ "${RemoveMasterTaint}" == "true" ];then
    kubectl taint node node-role.kubernetes.io/master- --all || true
  fi

  if [ "${PlatformType}" != "enterprise" ];then
    kubectl label node node-role.kubernetes.io/cnstack-infra="" --all --overwrite
    kubectl label node node-role.kubernetes.io/proxy="" --all --overwrite
  else
    kubectl taint node node-role.kubernetes.io/cnstack-infra=:NoSchedule -l node-role.kubernetes.io/cnstack-infra="" --overwrite
    kubectl taint node node-role.kubernetes.io/cnstack-infra=:NoSchedule -l node-role.kubernetes.io/proxy="" --overwrite
  fi
}

trident_process_init() {
  local ComponentToInstall=$1
  local PlatformCAPath=$2
  local PlatformCAKeyPath=$3
  local GenerateCAFlag=$4

  if [ "${ComponentToInstall}" != "" ];then
    local ComponentToInstallFlag="--component-to-install ${ComponentToInstall}"
  fi
  if [ "${PlatformCAPath}" != "" ];then
    local PlatformCAFlag="--ca-path ${PlatformCAPath} --key-path ${PlatformCAKeyPath}"
  fi
  trident on-sealer -f /root/.sealer/Clusterfile --sealer --dump-managed-cluster ${GenerateCAFlag} ${ComponentToInstallFlag} ${PlatformCAFlag}
}

trident_process_reconcile() {
  local ComponentToInstall=$1

  if [ "${ComponentToInstall}" != "" ];then
    local ComponentToInstallFlag="--component-to-install ${ComponentToInstall}"
  fi
  if [ ! -f /root/.sealer/Clusterfile ];then
    mkdir -p /root/.sealer/
    kubectl -n kube-system get cm sealer-clusterfile -ojsonpath='{.data.Clusterfile}' > /root/.sealer/Clusterfile
  fi
  trident on-sealer -f /root/.sealer/Clusterfile --sealer --dump-managed-cluster ${ComponentToInstallFlag}
}

gen_clusterinfo() {
  cat >/tmp/clusterinfo-cm.yaml <<EOF
---
apiVersion: v1
data:
  deployMode: "${deployMode}"
  gatewayExposeMode: "${gatewayExposeMode}"
  gatewayAddress: "${gatewayAddress}"
  gatewayDomain: "${gatewayDomain}"
  gatewayExternalIP: "${gatewayExternalIP}"
  gatewayInternalIP: "${gatewayInternalIP}"
  gatewayPort: "${gatewayPort}"
  gatewayAPIServerPort: "${gatewayAPIServerPort}"
  ingressAddress: "${ingressAddress}"
  ingressExternalIP: "${ingressExternalIP}"
  ingressInternalIP: "${ingressInternalIP}"
  ingressHttpPort: "${ingressHttpPort}"
  ingressHttpsPort: "${ingressHttpsPort}"
  harborAddress: "${harborAddress}"
  vcnsOssAddress: "${vcnsOssAddress}"
  clusterDomain: "${DNSDomain}"
  defaultIPStack: "${HostIPFamily}"
  registryURL: "${LocalRegistryURL}"
  registryExternalURL: "${LocalRegistryDomain}:5001"
  RegistryURL: "${LocalRegistryURL}"
  platformType: "${PlatformType}"
  clusterName: "cluster-local"
kind: ConfigMap
metadata:
  name: clusterinfo
  namespace: kube-public
EOF

  kubectl apply -f /tmp/clusterinfo-cm.yaml
}

helm_install() {
  for i in `seq 1 3`;do
    sleep 1
    helm -n kube-system upgrade -i $1 chart/$1 -f /tmp/ackd-helmconfig.yaml && return 0
  done
  return 1
}

prepare_helm_config() {
  if [ "$ClusterScale" == "" ] || [ "$ClusterScale" == "small" ];then
    hyMgrReqCpu=50m
    hyMgrReqMem=128Mi
    hyDsReqMem=64Mi
    hyFelixReqMem=128Mi
    hyWebReqCpu=10m
    hyWebReqMem=64Mi
  else
    hyMgrReqCpu=250m
    hyMgrReqMem=1024Mi
    hyDsReqMem=100Mi
    hyFelixReqMem=200Mi
    hyWebReqCpu=100m
    hyWebReqMem=100Mi
  fi

  cat >/tmp/ackd-helmconfig.yaml <<EOF
global:
  EnableLocalDNSCache: ${EnableLocalDNSCache}
  LocalDNSCacheIP: ${LocalDNSCacheIP}
  YodaSchedulerSvcIP: ${YodaSchedulerSvcIP}
  CoreDnsIP: ${CoreDnsIP}
  PodCIDR: ${PodCIDR}
  ClusterScale: "${ClusterScale}"
  MTU: "${MTU}"
  IPIP: ${IPIP}
  IPAutoDetectionMethod: ${IPAutoDetectionMethod}
  DisableFailureDomain: ${DisableFailureDomain}
  RegistryURL: ${RegistryURL}
  SuspendPeriodHealthCheck: ${SuspendPeriodHealthCheck}
  SuspendPeriodBroadcastHealthCheck: ${SuspendPeriodBroadcastHealthCheck}
  NumOfMasters: ${NumOfMasters}
  IPv6DualStack: ${IPv6DualStack}
  IPVSExcludeCIDRs: 10.103.97.2/32,1248:4003:10bb:6a01:83b9:6360:c66d:0002/128
init:
  cidr: ${PodCIDR%,*}
  ipVersion: "${HostIPFamily}"
  ingressControllerVIP: "${ingressControllerVIP}"
  apiServerVIP: "${apiServerVIP}"
  iamGatewayVIP: "${gatewayInternalIP}"
defaultIPFamily: IPv${HostIPFamily}
defaultIPRetain: ${DefaultIPRetain:-true}
multiCluster: true
daemon:
  vtepAddressCIDRs: ${VtepAddressCIDRs}
  hostInterface: "${ParalbHostInterface}"
  resources:
    requests:
      cpu: "0"
      memory: ${hyDsReqMem}
  felix:
    resources:
      requests:
        cpu: "0"
        memory: ${hyFelixReqMem}
manager:
  replicas: ${NumOfMasters}
  resources:
    requests:
      cpu: ${hyMgrReqCpu}
      memory: ${hyMgrReqMem}
webhook:
  replicas: ${NumOfMasters}
  resources:
    requests:
      cpu: ${hyWebReqCpu}
      memory: ${hyWebReqMem}
typha:
  replicas: ${NumOfMasters}
  resources:
    requests:
      cpu: ${hyWebReqCpu}
      memory: ${hyWebReqMem}
metricsServer:
  replicas: ${MetricsServerReplicas}
EOF
  cp -f /tmp/ackd-helmconfig.yaml /root/ackd-helmconfig.yaml
}

create_etcd_secret() {
  for NS in kube-system acs-system;do
    if kubectl get secret etcd-client-cert -n ${NS};then
      continue
    fi

    if ! kubectl create secret generic etcd-client-cert  \
      --from-file=ca.pem=/etc/kubernetes/pki/etcd/ca.crt --from-file=etcd-client.pem=/etc/kubernetes/pki/apiserver-etcd-client.crt  \
      --from-file=etcd-client-key.pem=/etc/kubernetes/pki/apiserver-etcd-client.key -n ${NS};then
      echo "failed to create etcd secret"
      return 1
    fi
  done
}

install_optional_addons() {
  Addons=$1
  IFS=,
  for addon in ${Addons};do
    if [ "$addon" == "kube-prometheus-stack" ];then
      addon="kube-prometheus-crds"
    fi
    helm_install ${addon} || utils_info "failed to install ${addon}"
  done
IFS="
"
}

wait_for_apiserver() {
  for i in `seq 1 24`;do
    sleep 5
    kubectl get ns && break
  done
  if [ $? -ne 0 ];then
    echo "failed to wait for apiserver ready"
    exit $?
  fi
}

create_subnet() {
  if kubectl get subnet init-2;then
    return 0
  fi

  HostIPFamily=$1
  PodCIDR=$2
  networkName=$3

  secondFamily=6
  if [ "$HostIPFamily" == "6" ];then
    secondFamily=4
  fi
  cat >/tmp/subnet2.yaml <<EOF
---
apiVersion: networking.alibaba.com/v1
kind: Subnet
metadata:
  name: init-2
  labels:
    webhook.hybridnet.io/ignore: "true"
spec:
  config:
    autoNatOutgoing: true
  network: ${networkName}
  range:
    cidr: ${PodCIDR##*,}
    version: "${secondFamily}"
EOF
  for i in `seq 1 16`;do
    kubectl apply -f /tmp/subnet2.yaml && break
    sleep 30
  done
  if [ $? -ne 0 ];then
    echo "failed to run kubectl apply -f /tmp/subnet2.yaml, ignore this, please apply it by yourself"
    return 1
  fi
}

health_check() {
  local SkipHealthCheck=$1

  if [ "${SkipHealthCheck}" = "true" ];then
    return 0
  fi

  sleep 15
  trident health-check && return 0

  echo "First time health check fail, sleep 30 and try again"
  sleep 30
  trident health-check --trigger-mode OnlyUnsuccessful && return 0

  echo "Second time health check fail, sleep 60 and try again"
  sleep 60
  trident health-check --trigger-mode OnlyUnsuccessful
}