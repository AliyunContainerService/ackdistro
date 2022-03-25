#!/bin/bash

# This script check the L2 and L3 network connection from this node to others

source /l0/utils/l0-utils.sh

myip=$POD_IP
errMsg=""

# L3 network
for node_ip in ${NODE_IP_LIST[*]}
do
    count=0
    while [[ true ]]; do
        ping -c 1 $node_ip >> /dev/null
        if [ `echo $?` -eq 0 ]; then
            #echo "Ping from src:node($myip) to dest:node($node_ip) success"
            break
        else
            count=$[${count}+1]
            if [[ ${count} -eq 2 ]]; then
                errMsg=$errMsg";Ping from src:node($myip) to dest:node($node_ip) failed"
                echo ${errMsg}
                break
            fi
            sleep 1
        fi
    done

done

if [[ "$errMsg" != "" ]];then
    Record "NODE_NETWORK_CHECK" "network" "fail" "$errMsg" "检查节点网络"
else
    Record "NODE_NETWORK_CHECK" "network" "pass" "check node network success" "检查节点网络"
fi

Return "${TestResults}"