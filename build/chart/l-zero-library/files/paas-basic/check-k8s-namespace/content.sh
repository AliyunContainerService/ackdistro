#!/usr/bin/env bash

source /l0/utils/l0-utils.sh

errMsg=""
items=$(kubectl get ns | grep -v STATUS | awk '{print $1";"$2";"$3}')
for item in ${items}; do
    arr=(${item//;/ })
    name=${arr[0]}
    status=${arr[1]}
    if [[ ${status} != "Active" ]]; then
        message=$(kubectl get ns $name)
        errMsg=${errMsg}"; 命名空间 [$name] 处于异常状态"
    fi
done

if [[ "$errMsg" == "" ]];then
    Record "CHECK_K8S_NAMESPACE" "k8s-basic" "pass" "all namespaces are healthy." "检查命名空间"
else
    Record "CHECK_K8S_NAMESPACE" "k8s-basic" "fail" "$errMsg" "检查命名空间"
fi

Return "${TestResults}"