#!/usr/bin/env bash

set -e

KUBE_VERSION=$1

if [[ "$KUBE_VERSION" == "" ]];then
    echo "Usage: bash build.sh VERSION"
    exit 1
fi

if [ ! -d $KUBE_VERSION ];then
    echo "Directory $KUBE_VERSION not found"
    exit 1
fi

rm -f image-anno-${KUBE_VERSION}
touch image-anno-${KUBE_VERSION}
i=0
for f in imageList-lite imageList-standard;do
  for l in `cat ${KUBE_VERSION}/$f`;do
    if [ "$l" == "" ];then
      continue
    fi
    if grep $l image-anno-${KUBE_VERSION};then
      continue
    fi
    echo "    ack-d-ctr-image${i}: $l" >> image-anno-${KUBE_VERSION}
    let i=i+1
  done
done
