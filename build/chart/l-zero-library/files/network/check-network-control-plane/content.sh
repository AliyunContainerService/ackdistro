#!/usr/bin/env bash

source /l0/utils/l0-utils.sh

errMsg=""
ret=0
check_k8s_network() {
    network_ds=""
    network_pods=""

    cnt=$(kubectl get ds -n kube-system | grep calico | wc -l)
    if [[ ${cnt} != "0" ]]; then
        echo "> 检查k8s集群的calico网络状态"
        network_ds=$(kubectl get ds -n kube-system | grep calico | awk '{print $1";"$2";"$3";"$4}')
        network_pods=$(kubectl get pod -n kube-system | grep calico | awk '{print $1";"$2";"$3";"$4}')
    fi

    cnt=$(kubectl get ds -n kube-system | grep flannel | wc -l)
    if [[ ${cnt} != "0" ]]; then
        echo "> 检查k8s集群的flannel网络状态"
        network_ds=$(kubectl get ds -n kube-system | grep flannel | awk '{print $1";"$2";"$3";"$4}')
        network_pods=$(kubectl get pod -n kube-system | grep flannel | awk '{print $1";"$2";"$3";"$4}')
    fi

    cnt=$(kubectl get ds -n kube-system | grep terway-vlan | wc -l)
    if [[ ${cnt} != "0" ]]; then
        echo "> 检查k8s集群的terway-vlan网络状态"
        network_ds=$(kubectl get ds -n kube-system | grep terway-vlan | awk '{print $1";"$2";"$3";"$4}')
        network_pods=$(kubectl get pod -n kube-system | grep terway-vlan | awk '{print $1";"$2";"$3";"$4}')
    fi

    cnt=$(kubectl get ds -n kube-system | grep rama-daemon | wc -l)
    if [[ ${cnt} != "0" ]]; then
        echo "> 检查k8s集群的rama网络状态"
        network_ds=$(kubectl get ds -n kube-system | grep rama-daemon | awk '{print $1";"$2";"$3";"$4}')
        network_pods=$(kubectl get pod -n kube-system | grep rama-daemon | awk '{print $1";"$2";"$3";"$4}')
    fi

    cnt=$(kubectl get ds -n kube-system | grep nimitz | wc -l)
    if [[ ${cnt} != "0" ]]; then
        echo "> 检查k8s集群的nimitz网络状态"
        network_ds=$(kubectl get ds -n kube-system | grep nimitz | awk '{print $1";"$2";"$3";"$4}')
        network_pods=$(kubectl get pod -n kube-system | grep nimitz | awk '{print $1";"$2";"$3";"$4}')
    fi

    # check daemonset
    for item in ${network_ds}; do
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
    for item in ${network_pods}; do
        arr=(${item//;/ })
        name=${arr[0]}
        status=${arr[2]}
        if [[ ${status} != "Running" ]]; then
            echo "network pod [$name] 处于异常状态: $status"
            ret=1
        fi
    done
}

check_k8s_network
if [[ "$ret" == "0" ]];then
    Record "NETWORK_CONTROL_PLANE_CHECK" "network" "pass" "basic network check succeeded, network pods are all healthy." "检查网络插件管控面"
else
    Record "NETWORK_CONTROL_PLANE_CHECK" "network" "fail" "$errMsg" "检查网络插件管控面"
fi

Return "${TestResults}"