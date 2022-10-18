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
    echo "MULTI_ARCH is not set, default is false, if you want build multi arch, please run 'bash build.sh TAG true'"
    MULTI_ARCH=false
fi

if [[ "$ARCH" == "" ]];then
    echo "ARCH is not set, default is amd64, if you want build other arch, please run 'bash build.sh TAG false ARCH'"
    ARCH=amd64
fi

KUBE_VERSION=`cat Metadata |grep version |awk '{print $2}' |tr -d '"|,'`

archs=$ARCH
if [[ "$MULTI_ARCH" == "true" ]];then
    archs="amd64,arm64"
fi

trident_version=1.14.0
if [ "$SKIP_DOWNLOAD_BINS" != "true" ];then
    IFS=","
    for arch in $archs;do
        rm -rf ${arch}
        mkdir -p ${arch}/bin
        mkdir -p ${arch}/rpm
        mkdir -p ${arch}/tgz

        bins=(kubectl kubelet kubeadm)
        for bin in ${bins[@]};do
            wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/bin/${arch}/${KUBE_VERSION}/${bin} -O ${arch}/bin/${bin}
        done

        bins=(helm seautil mc etcdctl)
        for bin in ${bins[@]};do
            wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/bin/${arch}/${bin} -O ${arch}/bin/${bin}
        done

        wget "https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/trident/release/trident_license_off-linux-${arch}_${trident_version}.bin" -O ${arch}/bin/trident

        if [ "$arch" == "amd64" ];then
          rpm_suffix=x86_64
        else
          rpm_suffix=aarch64
        fi

        rpms=(kubernetes-cni)
        for rpm in ${rpms[@]};do
            rpmfile=${rpm}.${rpm_suffix}.rpm
            wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/rpm/${arch}/${KUBE_VERSION}/${rpmfile} -O ${arch}/rpm/${rpmfile}
        done

        rpms=(socat-1.7.3.2-2.el7 libseccomp-2.3.1-4.el7)
        for rpm in ${rpms[@]};do
            rpmfile=${rpm}.${rpm_suffix}.rpm
            wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/rpm/${arch}/${rpmfile} -O ${arch}/rpm/${rpmfile}
        done

        if [ "$arch" == "amd64" ];then
            wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/tgz/${arch}/nvidia.tgz -O ${arch}/tgz/nvidia.tgz
        fi
        tgzs=(lvm-el7.tgz lvm-el8.tgz s3fs-el7.tgz s3fs-el8.tgz)
        for tgz in ${tgzs[@]};do
            wget https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/tgz/${arch}/${tgz} -O ${arch}/tgz/${tgz}
        done
    done
    IFS=" "
fi

echo -n `git log -1 --pretty=format:%h` > VERSION

#if [ "$(git branch --show-current)" == "main" ]; then
#  wget https://gosspublic.alicdn.com/ossutil/1.7.8/ossutil64?spm=a2c4g.11186623.0.0.bcbf1770zMJhXK -O ossutil64
#  chmod +x ossutil64
#  ./ossutil64 --endpoint http://oss-cn-hangzhou.aliyuncs.com cp -f build/imageList oss://acs-ecp/ack-agility/ack-distro-imagelist-main.info
#fi

#
# shellcheck disable=SC2016
sed 's/${ARCH}/${archs}/g' ./Kubefile

# Build sealer image
sealer build -f Kubefile -t ack-distro:${TAG} --platform linux/${archs} .