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

if ! grep "start-cnstack-koord-scheduler.sh" /etc/kubernetes/manifests/kube-scheduler.yaml; then
    sed -i "s#- kube-scheduler#- /start-cnstack-koord-scheduler.sh#g" /etc/kubernetes/manifests/kube-scheduler.yaml
fi
