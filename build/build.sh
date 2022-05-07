#!/usr/bin/env bash

set -x;set -e

if ! which sealer;then
    echo "sealer not found, please download latest sealer"
    exit 1
fi

TAG=$1
ARCH=$2

if [[ "$TAG" == "" ]];then
    echo "Usage: bash build.sh TAG"
    exit 1
fi

if [[ "$ARCH" == "" ]];then
    echo "ARCH is not set, default is amd64, if you want build other arch, please run bash build.sh TAG ARCH"
    ARCH=amd64
fi

bins=(helm kubectl kubelet kubeadm trident)
for bin in ${bins[@]};do
    wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/bin/${ARCH}/${bin} -O ${bin}
done

# Build sealer image
sealer build -m lite -t ack-distro:${TAG} --platform ${ARCH} .