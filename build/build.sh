#!/usr/bin/env bash

set -x;set -e

if ! which sealer;then
    echo "sealer not found, please download latest sealer"
    exit 1
fi

TAG=$1

if [[ "$TAG" == "" ]];then
    echo "Usage: bash build.sh TAG"
    exit 1
fi

bins=(helm kubectl kubelet kubeadm)
for bin in ${bins[@]};do
    [[ -f ${bin} ]] || wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/bin/amd64/${bin} -O ${bin}
done

sealer build -m lite -t ack-distro:${TAG} .