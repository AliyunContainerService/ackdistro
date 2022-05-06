#!/usr/bin/env bash

source /l0/utils/l0-utils.sh

check_has_apiserver_crash() {
    if kubectl -n kube-system get pod -l component=kube-apiserver | grep -w CrashLoopBackOff &>/dev/null;then
        return 0
    fi
    return 1
}

check_address_already_binded() {
    rlt=""
    crash_pods=$(kubectl -n kube-system get pod -l component=kube-apiserver | grep -w CrashLoopBackOff | awk '{print $1}')
    for item in ${crash_pods}; do
        kubectl -n kube-system logs ${item} -p --tail=10 | grep "bind: address already in use" &>/dev/null
        if [ $? -eq 0 ];then
            rlt=${rlt}","${item}
        fi
    done
    [[ "$rlt" == "" ]] && return 1
    rlt=${rlt:1}
    return 0
}

if ! check_has_apiserver_crash;then
    Record "K8S_APISERVER_CHECK" "k8s-apiserver" "pass" "Has no kube-apiserver crash, this case is OK." "检查K8s Apiserver"
    Return "${TestResults}"
fi

if check_address_already_binded;then
    Record "K8S_APISERVER_CHECK" "k8s-apiserver" "fail" "Apiserver pod[$rlt] crash, maybe because there are duplicate apiserver process on the same node, please see doc:[https://work.aone.alibaba-inc.com/issue/30034272]" "检查K8s Apiserver"
    Return "${TestResults}"
fi

Record "K8S_APISERVER_CHECK" "k8s-apiserver" "fail" "There are some apiserver pod[$rlt] crash in your cluster, but we can't find the reason, please ask [专有云敏捷PaaS容器技术支持群] for help." "检查K8s Apiserver"
Return "${TestResults}"