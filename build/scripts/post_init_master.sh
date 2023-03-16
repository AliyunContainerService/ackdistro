#!/usr/bin/env bash

set -x

KOORD_SCHE_VERSION=`cat KOORD_SCHE_VERSION`
KUBE_VERSION=`cat KUBE_VERSION`

if ! grep "${KOORD_SCHE_VERSION}" /etc/kubernetes/manifests/kube-scheduler.yaml; then
    sed -i "s#kube-scheduler:${KUBE_VERSION}#${KOORD_SCHE_VERSION}#g" /etc/kubernetes/manifests/kube-scheduler.yaml
fi

if ! grep "config=/etc/kubernetes/kube-scheduler-config.yaml" /etc/kubernetes/manifests/kube-scheduler.yaml; then
    sed -i "/    - kube-scheduler/a \    - --config=/etc/kubernetes/kube-scheduler-config.yaml" /etc/kubernetes/manifests/kube-scheduler.yaml
fi

if ! grep "dnsPolicy: ClusterFirstWithHostNet" /etc/kubernetes/manifests/kube-scheduler.yaml; then
    sed -i "/  hostNetwork: true/a \  dnsPolicy: ClusterFirstWithHostNet" /etc/kubernetes/manifests/kube-scheduler.yaml
fi

if ! grep "start-cnstack-koord-scheduler.sh" /etc/kubernetes/manifests/kube-scheduler.yaml; then
    sed -i "s#- kube-scheduler#- /start-cnstack-koord-scheduler.sh#g" /etc/kubernetes/manifests/kube-scheduler.yaml
fi

if [ "$ClusterScale" == "" ] || [ "$ClusterScale" == "small" ];then
  exit 0
elif [ "$ClusterScale" == "medium" ];then
  EtcdCPUReq=1
  EtcdMemReq="2Gi"
  APIServerCPUReq=4
  APIServerMemReq="8Gi"
  KCMCPUReq=4
  KCMMemReq="8Gi"
  SchedulerCPUReq=4
  SchedulerMemReq="8Gi"
elif [ "$ClusterScale" == "large" ];then
  EtcdCPUReq=1
  EtcdMemReq="2Gi"
  APIServerCPUReq=4
  APIServerMemReq="8Gi"
  KCMCPUReq=4
  KCMMemReq="8Gi"
  SchedulerCPUReq=4
  SchedulerMemReq="8Gi"
elif [ "$ClusterScale" == "xlarge" ];then
  EtcdCPUReq=8
  EtcdMemReq="16Gi"
  APIServerCPUReq=16
  APIServerMemReq="128Gi"
  KCMCPUReq=8
  KCMMemReq="32Gi"
  SchedulerCPUReq=8
  SchedulerMemReq="32Gi"
fi

sed -i "s#cpu: 100m#cpu: ${EtcdCPUReq}#g" /etc/kubernetes/manifests/etcd.yaml
sed -i "s#memory: 100Mi#memory: ${EtcdMemReq}#g" /etc/kubernetes/manifests/etcd.yaml
sed -i "s#cpu: 250m#cpu: ${APIServerCPUReq}\n        memory: ${APIServerMemReq}#g" /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i "s#cpu: 200m#cpu: ${KCMCPUReq}\n        memory: ${KCMMemReq}#g" /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -i "s#cpu: 100m#cpu: ${SchedulerCPUReq}\n        memory: ${SchedulerMemReq}#g" /etc/kubernetes/manifests/kube-scheduler.yaml