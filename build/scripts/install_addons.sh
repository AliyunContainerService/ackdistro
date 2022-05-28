#!/usr/bin/env bash
set -x

# Prepare envs
CoreDnsIP=`trident get-indexed-ip --cidr ${SvcCIDR} --index 10`

# Apply yamls
for f in `ls ack-distro-yamls/yamls`;do
  sed "s/##DNSDomain##/${DNSDomain}/g" ack-distro-yamls/yamls/${f} | kubectl apply -f -
done

# Prepare helm config
cat >/tmp/ackd-helmconfig.yaml <<EOF
globalconfig:
  CoreDnsIP: ${CoreDnsIP}
  PodCIDR: ${PodCIDR}
  MTU: "${MTU}"
  IPIP: ${IPIP}
  IPAutoDetectionMethod: ${IPAutoDetectionMethod}
  DisableFailureDomain: ${DisableFailureDomain}
  RegistryURL: ${RegistryURL}
  SuspendPeriodHealthCheck: ${SuspendPeriodHealthCheck}
  SuspendPeriodBroadcastHealthCheck: ${SuspendPeriodBroadcastHealthCheck}
  init:
    cidr: ${PodCIDR}
    ipVersion: "${IPVersion}"
EOF

# install kube core addons
helm -n kube-system upgrade -i kube-core chart/kube-core -f /tmp/ackd-helmconfig.yaml
kubectl create ns acs-system || true

# create etcd secret
for NS in kube-system acs-system;do
	if kubectl get secret etcd-client-cert -n ${NS};then
	  continue
	fi

	if ! kubectl create secret generic etcd-client-cert  \
    --from-file=ca.pem=/etc/kubernetes/pki/etcd/ca.crt --from-file=etcd-client.pem=/etc/kubernetes/pki/apiserver-etcd-client.crt  \
    --from-file=etcd-client-key.pem=/etc/kubernetes/pki/apiserver-etcd-client.key -n ${NS};then
    echo "failed to create etcd secret"
    exit 1
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