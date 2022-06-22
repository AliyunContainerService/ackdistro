#!/usr/bin/env bash

source /l0/utils/l0-utils.sh

errMsg=""
check_k8s_cs() {
    items=$(kubectl get cs | grep -v STATUS | awk '{print $1";"$2";"$3}')
    for item in ${items}; do
        arr=(${item//;/ })
        name=${arr[0]}
        status=${arr[1]}
        message=${arr[2]}
        if [[ ${status} != "Healthy" ]]; then
          errMsg=${errMsg}"; 组件 [$name] 处于不健康状态: status"
        fi
    done
}

check_master_pods() {
    items=$(kubectl get pod -n kube-system | egrep 'kube-(apiserver|scheduler|controller-manager)' | awk '{print $1";"$2";"$3}')
    for item in ${items}; do
        arr=(${item//;/ })
        name=${arr[0]}
        status=${arr[2]}
        if [[ ${status} != "Running" ]]; then
            kubectl get pod $name -n kube-system
            errMsg=${errMsg}"; pod [$name] 处于异常状态: $status"
        fi
    done
}

ret=""
check_k8s_cs
if [[ "$errMsg" == "" ]];then
    Record "K8S_CS_CHECK" "k8s-core" "pass" "all k8s componentstatus are healthy." "检查K8s Components"
else
    Record "K8S_CS_CHECK" "k8s-core" "fail" "$errMsg" "检查K8s Components"
fi

errMsg=""
check_master_pods
if [[ "$errMsg" == "" ]];then
    Record "MASTER_POD_CHECK" "k8s-core" "pass" "all master pods are healthy" "检查K8s Master Pods"
else
    Record "MASTER_POD_CHECK" "k8s-core" "fail" "$errMsg" "检查K8s Master Pods"
fi

Return "${TestResults}"