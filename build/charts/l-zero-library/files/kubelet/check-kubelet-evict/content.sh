#!/usr/bin/env bash

source /l0/utils/l0-utils.sh

check_has_evicted_pod() {
    kubectl get pod --all-namespaces=true -owide | grep Evicted &>/dev/null
    return $?
}

check_has_node_disk_pressure() {
    rlt=""
    nodes=$(kubectl get node | grep -v STATUS | awk '{print $1}')
    for item in ${nodes}; do
        status=`kubectl get node ${item} -ojsonpath='{.status.conditions[?(@.type=="DiskPressure")].status}'`
        if [[ "$status" == "True" ]];then
            rlt=${rlt}","${item}
        fi
    done
    [[ "$rlt" == "" ]] && return 1
    rlt=${rlt:1}
    return 0
}

check_has_node_pid_pressure() {
    rlt=""
    nodes=$(kubectl get node | grep -v STATUS | awk '{print $1}')
    for item in ${nodes}; do
        status=`kubectl get node ${item} -ojsonpath='{.status.conditions[?(@.type=="PIDPressure")].status}'`
        if [[ "$status" == "True" ]];then
            rlt=${rlt}","${item}
        fi
    done
    [[ "$rlt" == "" ]] && return 1
    rlt=${rlt:1}
    return 0
}

check_has_node_memory_pressure() {
    rlt=""
    nodes=$(kubectl get node | grep -v STATUS | awk '{print $1}')
    for item in ${nodes}; do
        status=`kubectl get node ${item} -ojsonpath='{.status.conditions[?(@.type=="MemoryPressure")].status}'`
        if [[ "$status" == "True" ]];then
            rlt=${rlt}","${item}
        fi
    done
    [[ "$rlt" == "" ]] && return 1
    rlt=${rlt:1}
    return 0
}

if ! check_has_evicted_pod;then
    Record "EVICTED_POD_CHECK" "kubelet" "pass" "Has no evicted pod." "检查是否存在被驱逐Pod"
    Return "${TestResults}"
fi

# there are some evicted pod, check reason
if check_has_node_disk_pressure;then
    Record "EVICTED_POD_CHECK" "kubelet" "fail" "Some node[${rlt}] has disk pressure, please see doc:[https://yuque.antfin-inc.com/optimalfleet/rgwy0x/emh6l2#a368422c] for help." "检查是否存在被驱逐Pod"
    Return "${TestResults}"
fi

if check_has_node_pid_pressure;then
    Record "EVICTED_POD_CHECK" "kubelet" "fail" "Some node[${rlt}] has pid pressure, please ask [专有云敏捷PaaS容器技术支持群] for help." "检查是否存在被驱逐Pod"
    Return "${TestResults}"
fi

if check_has_node_memory_pressure;then
    Record "EVICTED_POD_CHECK" "kubelet" "fail" "Some node[${rlt}] has memory pressure, please ask [专有云敏捷PaaS容器技术支持群] for help." "检查是否存在被驱逐Pod"
    Return "${TestResults}"
fi

Record "EVICTED_POD_CHECK" "kubelet" "fail" "There are some evicted pod in your cluster, but we can't find the reason, please ask [专有云敏捷PaaS容器技术支持群] for help." "检查是否存在被驱逐Pod"
Return "${TestResults}"