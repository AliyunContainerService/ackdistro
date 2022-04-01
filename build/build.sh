#!/usr/bin/env bash

export CHART_DIR_PATH=build/charts/

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

# Pull hybridnet helm charts
export HYBRIDNET_CHART_VERSION=0.1.1

helm pull hybridnet/hybridnet --version=$HYBRIDNET_CHART_VERSION
tar -zxvf hybridnet-$HYBRIDNET_CHART_VERSION.tgz -C $CHART_DIR_PATH
rm -f hybridnet-$HYBRIDNET_CHART_VERSION.tgz

# Build sealer image
sealer build -m lite -t ack-distro:${TAG} .
