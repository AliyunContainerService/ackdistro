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

if [ "$SKIP_DOWNLOAD_BINS" != "true" ];then
    bins=(helm kubectl kubelet kubeadm trident)
    for bin in ${bins[@]};do
        wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/bin/amd64/${bin} -O ${bin}
    done
fi

# Build sealer image
sealer build -m lite -t ack-distro:${TAG} .