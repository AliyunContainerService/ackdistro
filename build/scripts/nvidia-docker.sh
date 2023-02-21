#!/bin/bash

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -x

RPM_DIR=${scripts_path}/../rpm/nvidia

public::nvidia::enable_gpu_device_plugin() {
    sleep 10

    public::nvidia::deploy_static_pod
}

public::nvidia::install_nvidia_driver(){
    # see cos/release in branch agility-develop for details. Installing driver is not supported in trident.
    utils_info 'installing nvidia driver is not supported.'
    return
}


public::nvidia::install_nvidia_docker2(){
    sleep 3
    if  `which nvidia-container-runtime > /dev/null 2>&1` && [ $(echo $((docker info | grep nvidia) | wc -l)) -gt 1 ] ; then
        utils_info 'nvidia-container-runtime is already insatlled'
        return
    fi

    # 1. Install nvidia-container-runtime
    if ! output=$(rpm -ivh --force --nodeps `ls ${RPM_DIR}/*.rpm` 2>&1);then
        panic "failed to install rpm, output:${output}, maybe your rpm db was broken, please see https://cloudlinux.zendesk.com/hc/en-us/articles/115004075294-Fix-rpmdb-Thread-died-in-Berkeley-DB-library for help"
    fi

    # 2. Update docker daemon.json and reload docker daemon
    if [[ -f /etc/docker/daemon.json.rpmorig ]];then
        mv -f /etc/docker/daemon.json.rpmorig /etc/docker/daemon.json
    fi

    mkdir -p /etc/docker
    sed -i '2 i\
    \"default-runtime\": \"nvidia\",\
    \"runtimes\": {\
        \"nvidia\": {\
            \"path\": \"/usr/bin/nvidia-container-runtime\",\
            \"runtimeArgs\": []\
        }\
    },' /etc/docker/daemon.json

    # To do: we need make sure if it's better to reload rather than restart, e.g. service docker restart
    pkill -SIGHUP dockerd
    utils_info 'nvidia-docker2 installed'
}

# deploy nvidia plugin in static pod
public::nvidia::deploy_static_pod() {
    mkdir -p /etc/kubernetes/manifests
    RegistryURL=${RegistryURL:-sea.hub:5000}
    sed "s/sea\.hub:5000/${RegistryURL}/g" ${scripts_path}/../statics/nvidia-device-plugin.yml > /etc/kubernetes/manifests/nvidia-device-plugin.yml

    utils_info "nvidia-device-plugin yaml succefully deployed ..."
}

if ! public::nvidia::check_has_gpu ${scripts_path};then
    exit 0
fi
public::nvidia::install_nvidia_docker2
public::nvidia::enable_gpu_device_plugin