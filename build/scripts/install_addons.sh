#!/usr/bin/env bash

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -x

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

apiServerVIP=${apiServerInternalIP}
if [ "${gatewayInternalIP}" != "" ];then
  apiServerVIP=${gatewayInternalIP}
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
  apiServerVIP: "${apiServerVIP}"
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
helm -n kube-system upgrade -i kube-core chart/kube-core -f /tmp/ackd-helmconfig.yaml
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
  helm -n kube-system upgrade -i calico chart/calico -f /tmp/ackd-helmconfig.yaml
else
  helm -n kube-system upgrade -i hybridnet chart/hybridnet -f /tmp/ackd-helmconfig.yaml
fi

# install required addons
helm -n kube-system upgrade -i l-zero chart/l-zero -f /tmp/ackd-helmconfig.yaml
cp -f chart/open-local/values-acka.yaml chart/open-local/values.yaml
helm -n kube-system upgrade -i open-local chart/open-local -f /tmp/ackd-helmconfig.yaml
helm -n kube-system upgrade -i csi-hostpath chart/csi-hostpath -f /tmp/ackd-helmconfig.yaml
helm -n kube-system upgrade -i etcd-backup chart/etcd-backup -f /tmp/ackd-helmconfig.yaml

echo "sleep 15 for l-zero crds ready"
sleep 15
helm -n kube-system upgrade -i l-zero-library chart/l-zero-library -f /tmp/ackd-helmconfig.yaml

# install optional addons
IFS=,
for addon in ${Addons};do
  if [ "$addon" == "kube-prometheus-stack" ];then
    addon="kube-prometheus-crds"
  fi
  helm -n kube-system upgrade -i ${addon} chart/${addon} -f /tmp/ackd-helmconfig.yaml
done
IFS="
"

# for hybridnet
if [ "$Network" == "calico" ];then
  exit 0
fi

# sleep for hybridnet webhook ready
sleep 60

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
spec:
  config:
    autoNatOutgoing: true
  network: init
  range:
    cidr: ${PodCIDR##*,}
    version: "${secondFamily}"
EOF
  for i in `seq 1 6`;do
    sleep 60
    kubectl apply -f /tmp/subnet2.yaml && break
  done
  if [ $? -ne 0 ];then
    echo "failed to run kubectl apply -f /tmp/subnet2.yaml, ignore this, please apply it by yourself"
  fi

  kubectl  -n kube-system delete pod -lk8s-app=kube-dns
fi
