#!/usr/bin/env bash

source /l0/utils/l0-utils.sh

errMsg=""
items=$(kubectl get node | grep -v STATUS | awk '{print $1";"$2";"$3}')
for item in ${items}; do
    arr=(${item//;/ })
    name=${arr[0]}
    status=${arr[1]}
    role=${arr[2]}
    if [[ ${status} != "Ready" ]]; then
        message=$(kubectl get node $name)
        errMsg=${errMsg}"; 节点 [$name] 处于不健康状态"
    fi
done

if [[ "$errMsg" == "" ]];then
    Record "CHECK_K8S_NODE" "k8s-basic" "pass" "all nodes are healthy." "检查节点"
else
    Record "CHECK_K8S_NODE" "k8s-basic" "fail" "$errMsg" "检查节点"
fi

Return "${TestResults}"