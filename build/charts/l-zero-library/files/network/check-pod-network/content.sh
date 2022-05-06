#!/usr/bin/env bash

# Please retain this line
source /l0/utils/l0-utils.sh

myip=$POD_IP

###################################################
errMsg=""
# check pod ping nodes
for node_ip in ${NODE_IP_LIST[*]}
do
    # L3 network
    count=0
    while [[ true ]]; do
        ping -c 1 $node_ip >> /dev/null
        if [ `echo $?` -eq 0 ]; then
            # echo "Ping from src:pod($myip)/node($HOST_IP) to dest:node($node_ip) success"
            break
        else
            count=$[${count}+1]
            if [[ ${count} -eq 2 ]]; then
                errMsg=$errMsg";Ping from src:pod($myip)/node($HOST_IP) to dest:node($node_ip) failed."
                echo $errMsg
                break
            fi
            sleep 1
        fi
    done
done

if [[ "$errMsg" != "" ]];then
    Record "CHECK_POD_TO_NODE" "network" "fail" "$errMsg" "检查容器到节点网络"
else
    Record "CHECK_POD_TO_NODE" "network" "pass" "check pod to node success" "检查容器到节点网络"
fi

###################################################
# check pod ping pods
errMsg=""
for pod_node_ip_pair in ${POD_NODE_IP_PAIR_LIST[*]}
do
    pod_ip=`GetPodIp $pod_node_ip_pair`
    if [[ "$pod_ip" != "$myip" ]]; then
        count=0
        while [[ true ]]; do
            ping -c 1 $pod_ip >> /dev/null
            if [ `echo $?` -eq 0 ]; then
                #echo "Ping from src:pod($myip)/node($HOST_IP) to dest:pod($pod_ip) success"
                break
            else
                count=$[${count}+1]
                if [[ ${count} -eq 2 ]]; then
                    #ping -c 1 $pod_ip
                    errMsg=$errMsg";Ping from src:pod($myip)/node($HOST_IP) to dest:pod($pod_ip) failed"
                    echo $errMsg
                    break
                fi
                sleep 1
            fi
        done
    fi
done

if [[ "$errMsg" != "" ]];then
    Record "CHECK_POD_TO_POD" "network" "fail" "$errMsg" "检查容器到容器网络"
else
    Record "CHECK_POD_TO_POD" "network" "pass" "check pod to pod success" "检查容器到容器网络"
fi

###################################################
# create target pod
errMsg=""
CreatePodWithService
if [[ `echo $?` -ne 0 ]];then
    Record "CREATE_CHECK_POD" "network" "fail" "$errMsg" "创建靶Pod"
fi

###################################################
# check pod ping cluster ip service
errMsg=""
TIME_LIMIT=5

count=0
flag=0
while [[ true ]]; do
    curl $TARGET_SVC_URL --max-time ${TIME_LIMIT} >> /dev/null
    if [[ `echo $?` -eq 0 ]]; then
        #echo "Curl from src:pod($myip)/node($HOST_IP) to dest:service(${TARGET_SVC_URL}) success"
        Record "CHECK_POD_TO_CLUSTER_IP" "network" "pass" "check pod to cluster ip service success" "检查容器到Svc网络"
        break
    else
        count=$[${count}+1]
        if [[ ${count} -eq 6 ]]; then
            errMsg="Curl from src:pod($myip)/node($HOST_IP) to dest:service(${TARGET_SVC_URL}) failed"
            echo $errMsg
            Record "CHECK_POD_TO_CLUSTER_IP" "network" "fail" "$errMsg" "检查容器到Svc网络"
            break
        fi
        sleep 1
    fi
done

###################################################
# check pod ping nodeport service
errMsg=""
for node_ip in $NODE_IP_LIST
do
    # L3 network
    count=0
    while [[ true ]]; do
        curl ${node_ip}:$TARGET_NODEPORT --max-time ${TIME_LIMIT} > /dev/null 2>&1
        if [ `echo $?` -eq 0 ]; then
            #echo "Curl from src:pod($myip)/node($HOST_IP) to dest:nodeport_service(${node_ip}:${TARGET_NODEPORT}) success"
            break
        else
            count=$[${count}+1]
            if [[ ${count} -eq 4 ]]; then
                errMsg=$errMsg";Curl from src:pod($myip)/node($HOST_IP) to dest:nodeport_service(${node_ip}:${TARGET_NODEPORT}) failed"
                echo ${errMsg}
                break
            fi
            sleep 1
        fi
    done
done

if [[ "$errMsg" != "" ]];then
    Record "CHECK_POD_TO_NODEPORT" "network" "fail" "$errMsg" "检查容器到NodePort网络"
else
    Record "CHECK_POD_TO_NODEPORT" "network" "pass" "check pod to nodeport service success" "检查容器到NodePort网络"
fi


kube_dns_service_name="kube-dns.kube-system.svc"

###################################################
# check ping dns endpoint pods
errMsg=""
kube_dns_endpoints_ips=`kubectl -n kube-system get ep kube-dns -ojsonpath='{.subsets[0].addresses[*].ip}'`
for pod in `echo "$kube_dns_endpoints_ips"`
do
    count=0
    while [[ true ]]; do
        curl "$pod:53" -k --connect-timeout 15 > /dev/null 2>&1
        error_code=`echo $?`
        if [ $error_code -ne 0 ] && [ $error_code -ne 52 ]; then
            count=$[${count}+1]
            if [[ ${count} -eq 4 ]]; then
                #curl "$pod:53" -k --connect-timeout 15
                errMsg=$errMsg";Curl from src:pod($myip)/node($HOST_IP) to dest:dns_endpoint($pod:53) failed"
                echo $errMsg
                break
            fi
            sleep 1
        else
            #errMsg="Curl from src:pod($myip)/node($HOST_IP) to dest:dns_endpoint($pod:53) success"
            break
        fi
    done
done

if [[ "$errMsg" != "" ]];then
    Record "CHECK_POD_TO_DNS_ENDPOINT" "network" "fail" "$errMsg" "检查容器到DNS后端IP"
else
    Record "CHECK_POD_TO_DNS_ENDPOINT" "network" "pass" "check pod to dns endpoint success" "检查容器到DNS后端IP"
fi

###################################################
# check ping dns cluster ip
errMsg=""
kube_dns_service_ip=`kubectl -n kube-system get svc kube-dns -ojsonpath='{.spec.clusterIP}'`

count=0
while [[ true ]]; do
    curl "$kube_dns_service_ip:53" -k --connect-timeout 15 > /dev/null 2>&1
    error_code=`echo $?`
    if [ $error_code -ne 0 ] && [ $error_code -ne 52 ]; then
        count=$[${count}+1]
        if [[ ${count} -eq 4 ]]; then
            #curl "$kube_dns_service_ip:53" -k --connect-timeout 15
            errMsg="Curl from src:pod($myip)/node($HOST_IP) to dest:dns_service($kube_dns_service_ip:53) failed"
            echo $errMsg
            break
        fi
        sleep 1
    else
        #echo "Curl from src:pod($myip)/node($HOST_IP) to dest:dns_service($kube_dns_service_ip:53) success"
        break
    fi
done

if [[ "$errMsg" != "" ]];then
    Record "CHECK_POD_TO_DNS_CLUSTERIP" "network" "fail" "$errMsg" "检查容器到DNS服务IP"
else
    Record "CHECK_POD_TO_DNS_CLUSTERIP" "network" "pass" "check pod to dns cluseter ip success" "检查容器到DNS服务IP"
fi

###################################################
# check ping dns service name
count=0
while [[ true ]]; do
    curl "$kube_dns_service_name:53" -k --connect-timeout 15 > /dev/null 2>&1
    error_code=`echo $?`
    if [ $error_code -ne 0 ] && [ $error_code -ne 52 ]; then
        count=$[${count}+1]
        if [[ ${count} -eq 4 ]]; then
            #curl "$kube_dns_service_name:53" -k --connect-timeout 15
            errMsg="Curl from src:pod($myip)/node($HOST_IP) to dest:dns_service_domain($kube_dns_service_name:53) failed"
            echo $errMsg
            break
        fi
        sleep 1
    else
        #echo "Curl probe for pod($myip) -> kubernetes service($kube_dns_service_name:53) success"
        break
    fi
done

if [[ "$errMsg" != "" ]];then
    Record "CHECK_POD_TO_DNS_NAME" "network" "fail" "$errMsg" "检查容器到DNS域名"
else
    Record "CHECK_POD_TO_DNS_NAME" "network" "pass" "check pod to dns service name success" "检查容器到DNS域名"
fi

Return "${TestResults}"