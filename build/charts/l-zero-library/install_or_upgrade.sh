#!/usr/bin/env bash

set -x
set -e

app=l-zero-library

sedi() {
    local os=$(uname -s)
    if [ "$os" == "Darwin" ]; then
        sed -i "" "$@"
    else
        sed -i "$@"
    fi
}

get_registry_url(){
    if [[ "$REGISTRY" == "" ]];then
        image=`kubectl -n kube-system get deploy coredns -ojsonpath='{.spec.template.spec.containers[0].image}'`
        REGISTRY=${image%%/*}
    fi
}

get_registry_url

if [[ "$REGISTRY" == "" ]];then
    exit 1
fi

sedi "s#reg.docker.alibaba-inc.com#$REGISTRY#g" ./values.yaml

ns=ark-ops-library
kubectl get ns $ns &>/dev/null || kubectl create ns $ns
ns=acs-system
kubectl get ns $ns &>/dev/null || kubectl create ns $ns

if helmv3 status $app;then
    helmv3 upgrade $app -f ./values.yaml .
else
    helmv3 install -f ./values.yaml $app .
fi