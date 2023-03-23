#! /bin/bash

set -e

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "此脚本的入参为一个本地存在的docker镜像的tar包路径或者一个本地存在的docker镜像名"
  echo "此脚本会将传入的镜像tar包或者镜像名，转存到sealer registry当中"
  echo "Usage: $0 /root/image.tar #这是一个docker镜像save的tar包"
  echo "       $0 image.tgz #这是对一个docker镜像save的tar包进行gzip压缩的包"
  echo "       $0 nginx:latest #这是一个docker镜像名称"
  exit 0
fi

split_image_name() {
  ImageUrl=$1
  res="${ImageUrl//[^\/]}"
  PartNum=${#res}
  if [ ${PartNum} -eq 2 ];then
    Domain=$(echo $ImageUrl | cut -d'/' -f 2)
    Image=$(echo $ImageUrl | cut -d'/' -f 3)
  elif [ ${PartNum} -eq 1 ];then
    Domain=default
    Image=$(echo $ImageUrl | cut -d'/' -f 2)
  elif [ ${PartNum} -eq 0 ];then
    Domain=default
    Image=$ImageUrl
  fi
}

import_image() {
  if which docker;then
    docker load -i ${1} | cut -d' ' -f 3
  else
    ctr -n k8s.io image import ${1} | cut -d' ' -f 2
  fi
}

if echo "$1" | grep -q -E '\.tar$';then
  FullName=`import_image ${1}`
elif echo "$1" | grep -q -E '\.tgz$';then
  image=`tar -xvf $1`
  FullName=`import_image ${image}`
else
  FullName="$1"
fi

split_image_name $FullName

label=hostalias-set-by-push-registry
for m in `kubectl get no -owide  |grep master|awk '{print $6}'`;do
  sed -i "/${label}/d" /etc/hosts
  echo "${m} sealer.push.temp.url #${label}" >> /etc/hosts
  if which docker;then
    docker tag $ImageUrl sealer.push.temp.url:5000/$Domain/$Image
    docker push sealer.push.temp.url:5000/$Domain/$Image
  else
    nerdctl -n k8s.io tag $ImageUrl sealer.push.temp.url:5000/$Domain/$Image
    ctr -n k8s.io i push sealer.push.temp.url:5000/$Domain/$Image -k
  fi
done
sed -i "/${label}/d" /etc/hosts

echo "已成功转存到 registry-internal.adp.aliyuncs.com:5000/$Domain/$Image"