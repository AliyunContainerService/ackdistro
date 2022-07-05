#!/usr/bin/env bash

source /l0/utils/l0-utils.sh

check_has_pod_create_container_error() {
    if kubectl get pod --all-namespaces=true | grep CreateContainerError &>/dev/null;then
        return 0
    fi
    return 1
}

check_docker_overlay_mount() {
    rlt=""
    for ns in `kubectl get ns`;do
        for pod in `kubectl -n $ns get pod | grep CreateContainerError | awk '{print $1}'`; do
            kubectl -n $ns describe pod ${pod} | grep "error creating overlay mount" &>/dev/null
            if [ $? -eq 0 ];then
                rlt=${rlt}","${ns}/${pod}
            fi
        done
    done
    [[ "$rlt" == "" ]] && return 1
    rlt=${rlt:1}
    return 0
}

if ! check_has_pod_create_container_error;then
    Record "CreateContainerError_Check" "docker" "pass" "Has no pod CreateContainerError, this case is OK." "检查是否有容器创建失败"
    Return "${TestResults}"
fi

if check_docker_overlay_mount;then
    Record "CreateContainerError_Check" "docker" "fail" "pods[$rlt] are CreateContainerError, maybe because docker overlay mount on the node occur some error, please see doc:[https://work.aone.alibaba-inc.com/issue/29922094]" "检查是否有容器创建失败"
    Return "${TestResults}"
fi

Record "CreateContainerError_Check" "docker" "fail" "There are some pods[$rlt] are CreateContainerError in your cluster, but we can't find the reason, please ask [专有云敏捷PaaS容器技术支持群] for help." "检查是否有容器创建失败"
Return "${TestResults}"