#!/usr/bin/env bash

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -x

helm_install() {
  for i in `seq 1 3`;do
    sleep $i
    helm -n kube-system upgrade -i $1 chart/$1 -f /tmp/ackd-helmconfig.yaml && return 0
  done
  return 1
}

# copy generate adp license script
cp "${scripts_path}/../etc/generate-adp-license.sh" /usr/bin/ || true
chmod +x /usr/bin/generate-adp-license.sh || true

# Prepare envs
CoreDnsIP=`trident get-indexed-ip --cidr ${SvcCIDR%,*} --index 10` || panic "failed to get coredns svc ip"

YodaSchedulerSvcIP=`trident get-indexed-ip --cidr ${SvcCIDR%,*} --index 4` || panic "failed to get yoda svc ip"

RegistryDomain=${RegistryURL%:*}
# Apply yamls
for f in `ls ack-distro-yamls`;do
  sed "s/##DNSDomain##/${DNSDomain}/g" ack-distro-yamls/${f} | sed "s/##REGISTRY_IP##/${RegistryIP}/g" | sed "s/##REGISTRY_DOMAIN##/${RegistryDomain}/g" | kubectl apply -f -
done

#TODO
LocalDNSCacheIP=169.254.20.10
VtepAddressCIDRs="0.0.0.0/0,::/0"
if [ "$HostIPFamily" == "6" ];then
  LocalDNSCacheIP=fd00::aaaa::ffff:a
  VtepAddressCIDRs="::/0"
fi
NumOfMasters=$(kubectl get no -l node-role.kubernetes.io/master="" | grep -v NAME | wc -l)
MetricsServerReplicas=2
if [ $NumOfMasters -eq 1 ];then
  MetricsServerReplicas=1
fi

# Prepare helm config
cat >/tmp/ackd-helmconfig.yaml <<EOF
global:
  EnableLocalDNSCache: ${EnableLocalDNSCache}
  LocalDNSCacheIP: ${LocalDNSCacheIP}
  YodaSchedulerSvcIP: ${YodaSchedulerSvcIP}
  CoreDnsIP: ${CoreDnsIP}
  PodCIDR: ${PodCIDR}
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
  ingressControllerVIP: "${ingressInternalIP}"
  apiServerVIP: "${apiServerInternalIP}"
  iamGatewayVIP: "${gatewayInternalIP}"
defaultIPFamily: IPv${HostIPFamily}
multiCluster: true
daemon:
  vtepAddressCIDRs: ${VtepAddressCIDRs}
  hostInterface: "${ParalbHostInterface}"
manager:
  replicas: ${NumOfMasters}
webhook:
  replicas: ${NumOfMasters}
typha:
  replicas: ${NumOfMasters}
metricsServer:
  replicas: ${MetricsServerReplicas}
EOF

# wait 120s for apiserver ready
for i in `seq 1 12`;do
  sleep 10
  kubectl get ns && break
done
if [ $? -ne 0 ];then
  panic "failed to wait for apiserver ready"
fi

# install kube core addons
helm_install kube-core || panic "failed to install kube-core"
kubectl create ns acs-system || true
kubectl create ns cluster-local || true

# create etcd secret
for NS in kube-system acs-system;do
	if kubectl get secret etcd-client-cert -n ${NS};then
	  continue
	fi

	if ! kubectl create secret generic etcd-client-cert  \
    --from-file=ca.pem=/etc/kubernetes/pki/etcd/ca.crt --from-file=etcd-client.pem=/etc/kubernetes/pki/apiserver-etcd-client.crt  \
    --from-file=etcd-client-key.pem=/etc/kubernetes/pki/apiserver-etcd-client.key -n ${NS};then
    panic "failed to create etcd secret"
  fi
done

# install net plugin
if [ "$Network" == "calico" ];then
  helm_install calico || panic "failed to install calico"
else
  helm_install hybridnet || panic "failed to install hybridnet"
fi

# install required addons
helm_install l-zero || panic "failed to install l-zero"
cp -f chart/open-local/values-acka.yaml chart/open-local/values.yaml
helm_install open-local || panic "failed to install open-local"
helm_install csi-hostpath || panic "failed to install csi-hostpath"
helm_install etcd-backup || panic "failed to install etcd-backup"

echo "sleep 15 for l-zero crds ready"
sleep 15
helm_install l-zero-library || panic "failed to install l-zero-library"

# install optional addons
IFS=,
for addon in ${Addons};do
  if [ "$addon" == "kube-prometheus-stack" ];then
    addon="kube-prometheus-crds"
  fi
  helm_install ${addon} || utils_info "failed to install ${addon}"
done
IFS="
"

# for hybridnet
if [ "$Network" == "calico" ];then
  exit 0
fi

# sleep for hybridnet webhook ready
if [ "$IPv6DualStack" == "true" ];then
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
  network: init
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
  fi

  kubectl -n kube-system delete pod -lk8s-app=kube-dns
fi
