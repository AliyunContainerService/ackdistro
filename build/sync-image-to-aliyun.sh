#!/usr/bin/env bash

new_tag=$1
amd_img=$2
arm_img=$3
no_pull=$4

set -x;set -e

if ! which jq;then
    echo "please install jq first"
    exit 1
fi

a=`docker inspect ${amd_img} |jq .[0].Architecture  -r`
if [ "$a" != "amd64" ];then
    echo "${amd_img} is not amd64 image"
    exit 1
fi
b=`docker inspect ${arm_img} |jq .[0].Architecture  -r`
if [ "$b" != "arm64" ];then
    echo "${arm_img} is not arm64 image"
    exit 1
fi

for REPO in ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder;do
    if [ "$no_pull" != "true" ];then
        docker pull $amd_img
        docker pull $arm_img
    fi
    docker tag  $amd_img ${REPO}/${new_tag}-amd64
    docker push ${REPO}/${new_tag}-amd64
    docker tag  $arm_img ${REPO}/${new_tag}-arm64
    docker push ${REPO}/${new_tag}-arm64

    docker manifest rm ${REPO}/${new_tag} || true
    docker manifest create ${REPO}/${new_tag} ${REPO}/${new_tag}-amd64 ${REPO}/${new_tag}-arm64 --amend
    docker manifest annotate ${REPO}/${new_tag} ${REPO}/${new_tag}-amd64 --os linux --arch amd64
    docker manifest annotate ${REPO}/${new_tag} ${REPO}/${new_tag}-arm64 --os linux --arch arm64
    docker manifest push ${REPO}/${new_tag}
done