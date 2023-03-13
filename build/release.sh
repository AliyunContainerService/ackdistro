#!/usr/bin/env bash

set -x;set -e

if ! which sealer;then
    echo "sealer not found, please download latest sealer"
    exit 1
fi

KUBE_VERSION=$1
TAG=$2
AUTO_BUILD=$3

if [[ "$TAG" == "" ]];then
    echo "Usage: bash release.sh KUBE_VERSION TAG AUTO_BUILD"
    exit 1
fi
if [[ "$ADP_ACCESSKEYID" == "" ]];then
    echo "ADP_ACCESSKEYID required"
    exit 1
fi

if [ "$AUTO_BUILD" == "true" ];then
    export BUILD_MODE=standard; bash build.sh ${KUBE_VERSION} "" ${TAG} true
    export BUILD_MODE=lite; bash build.sh ${KUBE_VERSION} "" ${TAG}-lite true
fi

sealer login ack-agility-registry.cn-shanghai.cr.aliyuncs.com -u ${EcpDefImageHubUsername} -p ${EcpDefImageHubPassword}
sealer push ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:${TAG}-lite
sealer push ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:${TAG}

ossutil64 --access-key-id "${ADP_ACCESSKEYID}" --access-key-secret "${ADP_ACCESSKEYSECRET}" --endpoint http://oss-cn-hangzhou.aliyuncs.com --acl public-read-write cp -f ${KUBE_VERSION}/imageList-standard oss://ack-a-aecp/ack-distro/imageList/${TAG}-lite