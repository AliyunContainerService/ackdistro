#!/usr/bin/env bash

set -x;set -e

if ! which sealer;then
    echo "sealer not found, please download latest sealer"
    exit 1
fi

TAG=$1
MULTI_ARCH=$2
ARCH=$3

if [[ "$TAG" == "" ]];then
    echo "Usage: bash build.sh TAG"
    exit 1
fi

if [[ "$MULTI_ARCH" == "" ]];then
    echo "MULTI_ARCH is not set, default is false, if you want build multi arch, please run bash build.sh TAG true"
    MULTI_ARCH=false
fi

if [[ "$ARCH" == "" ]];then
    echo "ARCH is not set, default is amd64, if you want build other arch, please run bash build.sh TAG false ARCH"
    ARCH=amd64
fi

archs=$ARCH
if [[ "$MULTI_ARCH" == "true" ]];then
    archs="amd64,arm64"
fi

if [ "$SKIP_DOWNLOAD_BINS" != "true" ];then
    bins=(helm kubectl kubelet kubeadm trident)
    IFS=","
    for arch in $archs;do
      rm -rf ${arch}
      mkdir ${arch}
      for bin in ${bins[@]};do
          wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/bin/${arch}/${bin} -O ${arch}/${bin}
      done
    done
    IFS=" "
fi

# Build sealer image
sealer build -f Kubefile -t ack-distro:${TAG} --platform ${archs} .