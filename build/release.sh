#!/usr/bin/env bash

set -x;set -e

if ! which sealer;then
    echo "sealer not found, please download latest sealer"
    exit 1
fi

KUBE_VERSION=$1
TAG=$2

if [[ "$TAG" == "" ]];then
    echo "Usage: bash release.sh KUBE_VERSION TAG"
    exit 1
fi

sealer push ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:$TAG

ossutil64 --access-key-id "${ADP_ACCESSKEYID}" --access-key-secret "${ADP_ACCESSKEYSECRET}" --endpoint http://oss-cn-hangzhou.aliyuncs.com --acl public-read-write cp -f ${KUBE_VERSION}/imageList-standard oss://ack-a-aecp/ack-distro/imageList/$TAG