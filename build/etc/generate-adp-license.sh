#!/usr/bin/env bash

if [ "$1" == "" ] || [ "$1" == "-h" ];then
    echo "Usage: $0 get-finger
       $0 register LICENSE_INFO"
    exit 0
fi

if [ "$1" == "get-finger" ];then
    kubectl -n acs-system get secret cluster-fingerprint  -ojsonpath='{.data.fingerprint}' |base64 -d |tr -d "\n"
    exit 0
fi

if [ "$1" == "register" ];then
    license="$2"
    kubectl apply -f - <<EOF
kind: Secret
apiVersion: v1
metadata:
  name: license-ack-agility
  namespace: acs-system
  labels:
    adp.aliyuncs.com/application-name: adp
    adp.aliyuncs.com/license: 'true'
data:
  license:
    $(echo -n $license | base64 | tr -d "\n")
type: Opaque
EOF
    exit 0
fi