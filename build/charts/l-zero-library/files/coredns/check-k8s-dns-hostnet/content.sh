#!/bin/bash

source /l0/utils/l0-utils.sh
# This script check the 'kube-dns' service and dns pods connection from pod

myip=$POD_IP
kube_dns_service_name="kube-dns.kube-system.svc"
kube_dns_service_ip=`kubectl -n kube-system get svc kube-dns -ojsonpath='{.spec.clusterIP}'`
kube_dns_endpoints_ips=`kubectl -n kube-system get ep kube-dns -ojsonpath='{.subsets[0].addresses[*].ip}'`


count=0
while [[ true ]]; do
    curl "$kube_dns_service_name:53" -k --connect-timeout 15 > /dev/null 2>&1
    error_code=`echo $?`
    if [ $error_code -ne 0 ] && [ $error_code -ne 52 ]; then
        count=$[${count}+1]
        if [[ ${count} -eq 4 ]]; then
            curl "$kube_dns_service_name:53" -k --connect-timeout 15
            errMsg="Curl from src:node($myip) to dest:dns_service_domain($kube_dns_service_name:53) failed"
            echo $errMsg
            Record "CURL_DNS_SERVER_NAME" "kube_dns" "fail" "$errMsg" "Node中使用域名访问DNS服务"
            break
        fi
        sleep 2
    else
        errMsg="Curl from src:node($myip) to dest:dns_service_domain($kube_dns_service_name:53) success"
        echo $errMsg
        Record "CURL_DNS_SERVER_NAME" "kube_dns" "pass" "$errMsg" "Node中使用域名访问DNS服务"
        break
    fi
done


count=0
while [[ true ]]; do
    curl "$kube_dns_service_ip:53" -k --connect-timeout 15 > /dev/null 2>&1
    error_code=`echo $?`
    if [ $error_code -ne 0 ] && [ $error_code -ne 52 ]; then
        count=$[${count}+1]
        if [[ ${count} -eq 4 ]]; then
            curl "$kube_dns_service_ip:53" -k --connect-timeout 15
            errMsg="Curl from src:node($myip) to dest:dns_service($kube_dns_service_ip:53) failed"
            echo $errMsg
            Record "CURL_DNS_SERVER_IP" "kube_dns" "fail" "$errMsg" "Node中使用ClusterIP访问DNS服务"
            break
        fi
        sleep 2
    else
        errMsg="Curl from src:node($myip) to dest:dns_service($kube_dns_service_ip:53) success"
        echo $errMsg
        Record "CURL_DNS_SERVER_IP" "kube_dns" "pass" "$errMsg" "Node中使用ClusterIP访问DNS服务"
        break
    fi
done


errMsg=""
for pod in `echo "$kube_dns_endpoints_ips"`
do
    count=0
    while [[ true ]]; do
        curl "$pod:53" -k --connect-timeout 15 > /dev/null 2>&1
        error_code=`echo $?`
        if [ $error_code -ne 0 ] && [ $error_code -ne 52 ]; then
            count=$[${count}+1]
            if [[ ${count} -eq 4 ]]; then
                curl "$pod:53" -k --connect-timeout 15
                errMsg="Curl from src:node($myip) to dest:dns_endpoint($pod:53) failed"
                echo $errMsg
                Record "CURL_DNS_ENDPOINT" "kube_dns" "fail" "$errMsg" "Node中使用后端PodIP访问DNS服务"
                break
            fi
            sleep 2
        else
            errMsg="Curl from src:node($myip) to dest:dns_endpoint($pod:53) success"
            echo $errMsg
            Record "CURL_DNS_ENDPOINT" "kube_dns" "pass" "$errMsg" "使用后端PodIP访问DNS服务"
            break
        fi
    done
done

Return "${TestResults}"