#!/usr/bin/env bash

# Prepare envs
SvcCIDR=${SvcCIDR:-10.96.0.0/16}
CoreDnsIP=`trident get-indexed-ip --cidr ${SvcCIDR} --index 10`
if [ "$Gateway" == "" ];then
  Gateway=`trident get-indexed-ip --cidr ${PodCIDR} --index 1`
fi
DNSDomain=${DNSDomain:-cluster.local}

# Apply yamls
for f in `ls ack-distro-yamls/`;do
  sed "s/##DNSDomain##/${DNSDomain}/g" ack-distro-yamls/${f} | kubectl apply -f -
done

# Prepare helm config
cat >/tmp/ackd-helmconfig.yaml <<EOF
globalconfig:
  CoreDnsIP: ${CoreDnsIP}
  PodCIDR: ${PodCIDR:-100.64.0.0/16}
  Gateway: ${Gateway}
  IPVersion: "${IPVersion:-4}"
  MTU: "${MTU:-4}"
  IPIP: ${IPIP:-Always}
  IPAutoDetectionMethod: ${IPAutoDetectionMethod:-can-reach=8.8.8.8}
  DisableFailureDomain: ${DisableFailureDomain:-false}
  RegistryURL: ${RegistryURL:-sea.hub:5000}
  SuspendPeriodHealthCheck: ${SuspendPeriodHealthCheck:-false}
  SuspendPeriodBroadcastHealthCheck: ${SuspendPeriodBroadcastHealthCheck:-false}
EOF

# install kube core addons
helm -n kube-system upgrade -i kube-core chart/kube-core -f /tmp/ackd-helmconfig.yaml
kubectl create ns acs-system || true

# install net plugin
if [ "$Network" == "calico" ];then
  helm -n kube-system upgrade -i calico chart/calico -f /tmp/ackd-helmconfig.yaml
else
  helm -n kube-system upgrade -i hybridnet chart/hybridnet -f /tmp/ackd-helmconfig.yaml
fi

# install required addons
helm -n kube-system upgrade -i l-zero chart/l-zero -f /tmp/ackd-helmconfig.yaml
helm -n kube-system upgrade -i open-local chart/open-local -f /tmp/ackd-helmconfig.yaml
helm -n kube-system upgrade -i etcd-backup chart/etcd-backup -f /tmp/ackd-helmconfig.yaml

echo "sleep 15 for l-zero crds ready"
sleep 15
helm -n acs-system upgrade -i l-zero-library chart/l-zero-library -f /tmp/ackd-helmconfig.yaml

# install optional addons
IFS=,
for addon in ${Addons};do
 helm -n acs-system upgrade -i ${addon} chart/${addon} /tmp/ackd-helmconfig.yaml
done