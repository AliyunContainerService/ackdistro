#!/usr/bin/env bash

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -x

set_logrotate() {
  # logrotate
  cat >/etc/logrotate.d/allvarlogs <<EOF
/var/log/*.log
/var/log/messages {
    copytruncate
    missingok
    notifempty
    compress
    hourly
    maxsize 100M
    rotate 5
    dateext
    dateformat -%Y%m%d-%s
    create 0644 root root
}
EOF

  if [ ! -f "/etc/cron.hourly/logrotate" ]; then
    cp "${scripts_path}"/logrotate /etc/cron.hourly/logrotate
  fi
}

if [ "${DisableLogRotate}" != "true" ];then
  set_logrotate
fi

# copy bins
chmod +x ${scripts_path}/../bin/*
cp -f ${scripts_path}/../bin/* /usr/bin/ || true

configure_ipv6="net.ipv6.conf.all.disable_ipv6 = 0"
echo $configure_ipv6 > /etc/sysctl.d/ack-d-enable-ipv6.conf
if ! grep "${configure_ipv6}" /etc/sysctl.conf;then
  echo "${configure_ipv6}" >> /etc/sysctl.conf
fi
if ! sysctl --system;then
  echo "failed to run sysctl, please check"
  exit 1
fi

KUBELET_EXTRA_ARGS="KUBELET_EXTRA_ARGS=--node-labels=ack-d.alibabacloud.com/managed-node=true"

if [ "${HostIP}" = "" ];then
  echo "Can't find HostIP in env, skip configure --node-ip"
else
  KUBELET_EXTRA_ARGS="${KUBELET_EXTRA_ARGS} --node-ip=${HostIP}"
  family_of_ip_need_get=6
  if [ "${HostIPFamily}" == "6" ];then
    family_of_ip_need_get=4
  fi

  chmod +x ./bin/trident
  cp -f ./bin/trident /usr/bin/trident
  anotherIP=`trident get-default-route-ip --ip-family ${family_of_ip_need_get}`
  if [ $? -eq 0 ] && [ "${anotherIP}" != "" ];then
    KUBELET_EXTRA_ARGS="${KUBELET_EXTRA_ARGS},${anotherIP}"
  fi
fi

ARCH=`arch`
if [ "$ARCH" = "x86_64" ];then
  if lspci | grep -i nvidia > /dev/null 2>&1;then
    NVIDIA_GPU_NAME=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader --id=0 | sed -e 's/ /-/g')
    if [[ "$NVIDIA_GPU_NAME" = "" ]]; then
      echo 'nvidia GPU name query failed, please check using `nvidia-smi --query-gpu=gpu_name  --format=csv,noheader --id=0 `'
      exit 1
    fi

    NVIDIA_GPU_COUNT=$(nvidia-smi -L | wc -l)
    if [[ "$NVIDIA_GPU_COUNT" = "0" ]]; then
      echo 'nvidia GPU count query failed, please check using `nvidia-smi -L | wc -l`'
      exit 1
    fi

    NVIDIA_GPU_MEMORY=$(nvidia-smi --id=0 --query-gpu=memory.total --format=csv,noheader | sed -e 's/ //g')
    if [[ "$NVIDIA_GPU_MEMORY" = "" ]]; then
      echo 'nvidia GPU memory resource query failed, please check using `nvidia-smi --id=0 --query-gpu=memory.total  --format=csv,noheader`'
      exit 1
    fi
    KUBELET_EXTRA_ARGS="${KUBELET_EXTRA_ARGS} --node-labels=aliyun.accelerator/nvidia_name=$NVIDIA_GPU_NAME,aliyun.accelerator/nvidia_count=$NVIDIA_GPU_COUNT,aliyun.accelerator/nvidia_mem=$NVIDIA_GPU_MEMORY"
  fi
fi

if ! echo $KUBELET_EXTRA_ARGS > /etc/sysconfig/kubelet;then
  echo $KUBELET_EXTRA_ARGS > /etc/default/kubelet
fi