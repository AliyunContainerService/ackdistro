#!/usr/bin/env bash

source /l0/utils/l0-utils.sh

errMsg=""
ret=0
check_kube_proxy() {
    proxy_ds=""
    proxy_pods=""

    proxy_ds=$(kubectl get ds -n kube-system | grep kube-proxy | awk '{print $1";"$2";"$3";"$4}')
    proxy_pods=$(kubectl get pod -n kube-system | grep kube-proxy | awk '{print $1";"$2";"$3";"$4}')

    # check daemonset
    for item in ${proxy_ds}; do
        arr=(${item//;/ })
        ds=${arr[0]}
        desired=${arr[1]}
        ready=${arr[3]}
        if [[ ${desired} != ${ready} ]]; then
            echo "daemonset[$ds] 未达到终态pod数目，期望数目[$desired]，实际数目[$ready]"
            ret=1
        fi
    done
    # check pods
    for item in ${proxy_pods}; do
        arr=(${item//;/ })
        name=${arr[0]}
        status=${arr[2]}
        if [[ ${status} != "Running" ]]; then
            echo "network pod [$name] 处于异常状态: $status"
            ret=2
        fi
    done
}

check_kube_proxy
if [[ "$ret" == "0" ]];then
    Record "KUBE_PROXY_CHECK" "kube-proxy" "pass" "kube proxy basic check succeeded." "检查K8s Proxy"
else
    Record "KUBE_PROXY_CHECK" "kube-proxy" "fail" "$errMsg" "检查K8s Proxy"
fi

Return "${TestResults}"