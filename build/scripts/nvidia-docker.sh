#!/bin/bash

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

# NVIDIA_VERSION=v1.0.1
GPU_FOUNDED=0

# Check if customer buys gpu capablities inaglity
GPU_SUPPORT=0

RPM_DIR=${scripts_path}/../rpm/nvidia

public::nvidia::check(){
    if [ "$ARCH" != "amd64" ];then
        utils_info "gpu now not support $ARCH"
        return
    fi
    if which nvidia-smi;then
        GPU_SUPPORT=1
    fi
}

public::nvidia::enable_gpu_capability(){
    utils_arch_env
    public::nvidia::check
    if [[ "0" == "$GPU_SUPPORT" ]]; then
        return
    fi

    kube::nvidia::detect_gpu
    if [[ "1" == "$GPU_FOUNDED" ]]; then
        public::nvidia::install_nvidia_docker2
        public::nvidia::enable_gpu_in_node
    fi
}

public::nvidia::enable_gpu_device_plugin() {
    if [[ "0" == "$GPU_SUPPORT" ]] || [[ "0" == "$GPU_FOUNDED" ]]; then
        return
    fi

    sleep 10
    public::nvidia::deploy_static_pod
}

kube::nvidia::detect_gpu(){
    set +e

    tar -xvf ${scripts_path}/../tgz/nvidia.tgz -C ${scripts_path}/../rpm/
    kube::nvidia::setup_lspci
    lspci | grep -i nvidia > /dev/null 2>&1
    if [[ "$?" == "0" ]]; then
        export GPU_FOUNDED=1
    fi
    set -e
}

kube::nvidia::setup_lspci(){
    if utils_command_exists lspci; then
        return
    fi
    utils_info "lspci command not exist, install it"
    rpm -ivh --force --nodeps ${RPM_DIR}/pciutils*.rpm
    if [[ "$?" != "0" ]]; then
        utils_error "failed to install pciutils via command (rpm -ivh --force --nodeps ${RPM_DIR}/pciutils*.rpm) in dir ${PWD}, please run it for debug"
        exit 1
    fi
}


public::nvidia::install_nvidia_driver(){
    # see cos/release in branch agility-develop for details. Installing driver is not supported in trident.
    utils_info 'installing nvidia driver is not supported.'
    return
}


public::nvidia::install_nvidia_docker2(){
    set +e
    sleep 3
    if  `which nvidia-container-runtime > /dev/null 2>&1` && [ $(echo $((docker info | grep nvidia) | wc -l)) -gt 1 ] ; then
        utils_info 'nvidia-container-runtime is already insatlled'
        return
    fi

    # 1. Install nvidia-container-runtime
    if ! output=$(rpm -ivh --force --nodeps `ls ${RPM_DIR}/*.rpm` 2>&1);then
        utils_error "failed to install rpm, output:${output}, maybe your rpm db was broken, please see https://cloudlinux.zendesk.com/hc/en-us/articles/115004075294-Fix-rpmdb-Thread-died-in-Berkeley-DB-library for help"
        exit 1
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

    set -e
}

public::nvidia::enable_gpu_in_node(){
    cfg=/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    if grep "aliyun\.accelerator\/nvidia_name" ${cfg};then
        utils_info 'nvidia-gpu is already enabled'
        return
    fi

    NVIDIA_GPU_NAME=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader --id=0 | sed -e 's/ /-/g')
    if [[ "$NVIDIA_GPU_NAME" == "" ]]; then
        utils_error 'nvidia GPU name query failed, please check using `nvidia-smi --query-gpu=gpu_name  --format=csv,noheader --id=0 `'
        exit 1
    fi

    NVIDIA_GPU_COUNT=$(nvidia-smi -L | wc -l)
    if [[ "$NVIDIA_GPU_COUNT" == "0" ]]; then
        utils_error 'nvidia GPU count query failed, please check using `nvidia-smi -L | wc -l`'
        exit 1
    fi

    NVIDIA_GPU_MEMORY=$(nvidia-smi --id=0 --query-gpu=memory.total --format=csv,noheader | sed -e 's/ //g')
    if [[ "$NVIDIA_GPU_MEMORY" == "" ]]; then
        utils_error 'nvidia GPU memory resource query failed, please check using `nvidia-smi --id=0 --query-gpu=memory.total  --format=csv,noheader`'
        exit 1
    fi

    KUBELET_EXTRA_ARGS="--node-labels=aliyun.accelerator/nvidia_name=$NVIDIA_GPU_NAME,aliyun.accelerator/nvidia_count=$NVIDIA_GPU_COUNT,aliyun.accelerator/nvidia_mem=$NVIDIA_GPU_MEMORY"
    #sed -i '/^ExecStart=$/iEnvironment="KUBELET_EXTRA_ARGS=--feature-gates=DevicePlugins=true"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    sed -i "s@KUBELET_EXTRA_ARGS=@KUBELET_EXTRA_ARGS=$KUBELET_EXTRA_ARGS\ @g" ${cfg}

    systemctl daemon-reload
    systemctl restart kubelet

    nodename=$(hostname | tr A-Z a-z)
    utils_info "if you are run $0 by yourself, please run (kubectl label node $nodename aliyun.accelerator/nvidia_name=$NVIDIA_GPU_NAME aliyun.accelerator/nvidia_count=$NVIDIA_GPU_COUNT aliyun.accelerator/nvidia_mem=$NVIDIA_GPU_MEMORY)"
}


# deploy nvidia plugin in static pod
public::nvidia::deploy_static_pod() {
    cp -f ${scripts_path}/../statics/nvidia-device-plugin.yml /etc/kubernetes/manifests/nvidia-device-plugin.yml

    utils_info "nvidia-device-plugin yaml succefully deployed ..."
}

public::nvidia::enable_gpu_capability
public::nvidia::enable_gpu_device_plugin