#!/usr/bin/env bash

source /l0/utils/l0-utils.sh

errMsg=""
items=$(kubectl get pod -n kube-system -l trident.apsara-stack.alibaba-inc.com/task-generated!=true | grep -v STATUS | egrep -v '(Completed|Running)' | awk '{print $1";"$2";"$3";"$4}')
for item in ${items}; do
    arr=(${item//;/ })
    ns=kube-system
    name=${arr[0]}
    status=${arr[2]}
    errMsg=${errMsg}"; pod[$name] in namespace[$ns] 处于异常状态: $status"
done

if [[ "$errMsg" == "" ]];then
    Record "CHECK_K8S_POD" "k8s-basic" "pass" "all pods are healthy." "检查异常Pod" "warning"
else
    Record "CHECK_K8S_POD" "k8s-basic" "fail" "$errMsg" "检查异常Pod" "warning"
fi

Return "${TestResults}"