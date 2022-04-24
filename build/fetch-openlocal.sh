#!/usr/bin/env bash

tag=$1

if [[ "$tag" == "" ]];then
    tag=main
fi

mkdir -p /tmp/open-local
cd /tmp/open-local
git init
git remote add -f origin https://github.com/alibaba/open-local.git

git config core.sparseCheckout true
echo "helm/" >> .git/info/sparse-checkout

git pull origin ${tag}

cd -
rm -rf open-local
cp -r /tmp/open-local/helm open-local