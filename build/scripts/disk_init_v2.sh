#!/bin/sh

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

# how to use: `sh disk_init.sh -d${deviceName}`
set -x

# Step 0: get device and parts size
dev=${StorageDevice}
etcdDev=${EtcdDevice}
container_runtime_size=${DockerRunDiskSize}
kubelet_size=${KubeletRunDiskSize}
file_system=${DaemonFileSystem}
container_runtime="docker"

if [ -z "$file_system" ]; then
    file_system="ext4"
    utils_info "set file system to default value - ${file_system}"
fi

mkfsForce() {
  if [ "$file_system" = "ext4" ];then
    mkfs.ext4 -F "$1"
  elif [ "$file_system" = "xfs" ];then
    mkfs.xfs -f "$1"
  else
    panic "file system $file_system is not supported now"
  fi
}

mountEtcd() {
    if [[ $etcdDev == *"nvme"* ]]; then
        mount |grep ^$etcdDev[p0-9]*|grep /var/lib/etcd
        if [ "$?" == "0" ]; then
            utils_info "$etcdDev has been mounted already, and in correct way~"
            return
        fi
    else
        mount |grep ^$etcdDev[0-9]*|grep /var/lib/etcd
        if [ "$?" == "0" ]; then
            utils_info "$etcdDev has been mounted already, and in correct way~"
            return
        fi
    fi

    mkfsForce $etcdDev
    mkdir -p /var/lib/etcd
    output=$(mount $etcdDev /var/lib/etcd 2>&1); [[ $? -ne 0 ]] && panic "failed to mount $etcdDev: $output"
    now=`date +'%Y-%m-%d-%H-%M-%S'`
    cp -r /var/lib/etcd/ /tmp/etcd-data-backup-${now}
    output=$(rm -rf /var/lib/etcd/* 2>&1); [[ $? -ne 0 ]] && panic "failed to rm /var/lib/etcd/*: $output"
    echo "$etcdDev /var/lib/etcd ${file_system} defaults 0 0" >> /etc/fstab
}

# Step 0: init etcd device
if utils_shouldMkFs $etcdDev;then
    mountEtcd
fi

# Step 1: check val
if ! utils_shouldMkFs $dev; then
    utils_info "device is empty! exit..."
    exit 0
fi
if [ -z "$container_runtime_size" ]; then
    container_runtime_size="100"
    utils_info "set partition /var/lib/$container_runtime size to default size - 100G"
fi
if [ -z "$kubelet_size" ]; then
    kubelet_size="100"
    utils_info "set partition /var/lib/kubelet size to default size - 100G"
fi

# Step 2: create vg
devPrefix="/dev/"
vgName="ackdistro-pool"
if [[ $dev =~ $devPrefix ]]
then
    # check each dev name
    OLD_IFS="$IFS"
    IFS=","
    arr=($dev)
    IFS="$OLD_IFS"
    devForVG=""
    for temp in ${arr[@]};do
        if [[ $temp =~ $devPrefix ]];then
            echo "input device is "$temp
        else
            panic "input device name is error, must be /dev/***"
        fi
        devForVG=$devForVG" "$temp
    done

    vgs $vgName
    if [ "$?" != "0" ]; then
        echo "create a VG called "$vgName
        output0=$(vgcreate -f $vgName $devForVG 2>&1)
        if [ "$?" != "0" ]; then
            panic "failed to create vg: $output0"
        fi
    else
        echo "vg "$vgName" exists!"
    fi

else
    vgName=$dev
fi

# Step 3: create lv
sed -i "/\\/var\\/lib\\/kubelet/d"  /etc/fstab
sed -i "/\\/var\\/lib\\/${container_runtime}/d"  /etc/fstab
sed -i "/\\/var\\/lib\\/${container_runtime}\\/logs/d"  /etc/fstab

lv_container_name="container"
lv_kubelet_name="kubelet"

container_runtime_size=$container_runtime_size"Gi"
kubelet_size=$kubelet_size"Gi"

lvs|grep $lv_container_name
if [ "$?" != "0" ]; then
    output1=$(lvcreate --name $lv_container_name --size $container_runtime_size $vgName -y 2>&1)
    if [ "$?" != "0" ]; then
        panic "failed to create $lv_container_name lv: $output1"
    fi
else
    utils_info "lv $lv_container_name exists!"
fi

lvs|grep $lv_kubelet_name
if [ "$?" != "0" ]; then
    output2=$(lvcreate --name $lv_kubelet_name --size $kubelet_size $vgName -y 2>&1)
    if [ "$?" != "0" ]; then
        panic "failed to create $lv_kubelet_name lv: $output2"
    fi
else
    utils_info "lv $lv_kubelet_name exists!"
fi

# Step 3.5: sleep a little while
sleep 1s

# Step 4: umount before mkfs
umount /var/lib/kubelet
if [ "$?" != "0" ]; then
  utils_info "failed to umount, maybe you should clean this node before join"
fi
umount /var/lib/${container_runtime}
if [ "$?" != "0" ]; then
  utils_info "failed to umount, maybe you should clean this node before join"
fi

# Step 5: make filesystem
if ! blkid|grep $lv_container_name|grep ${file_system}; then
    # This func will exit when fail
    mkfsForce /dev/$vgName/$lv_container_name
else
    utils_info "lv /dev/$vgName/$lv_container_name has file system"
fi

if ! blkid|grep $lv_kubelet_name|grep ${file_system}; then
    # This func will exit when fail
    mkfsForce /dev/$vgName/$lv_kubelet_name
else
    utils_info "lv /dev/$vgName/$lv_kubelet_name has file system"
fi

# Step 6: umount before mount
umount /var/lib/kubelet
if [ "$?" != "0" ]; then
  utils_info "failed to umount, maybe you should clean this node before join"
fi
umount /var/lib/${container_runtime}
if [ "$?" != "0" ]; then
  utils_info "failed to umount, maybe you should clean this node before join"
fi

# https://unix.stackexchange.com/a/474749
systemctl daemon-reexec

# Step 7: mount /var/lib/${container_runtime}
mkdir -p /var/lib/${container_runtime}
output5=$(mount /dev/$vgName/$lv_container_name /var/lib/${container_runtime} 2>&1)
if [ "$?" != "0" ]; then
  if echo "$output5" |grep "is already mounted";then
    utils_info "already mounted, continue"
  else
    utils_info "disk_init.sh lsblk result:"
    lsblk
    utils_info "disk_init.sh mount -a result:"
    mount -a
    panic "failed to exec [mount /dev/$vgName/$lv_container_name /var/lib/docker]: $output5"
  fi
fi
mkdir -p /var/lib/${container_runtime}/logs

# Step 8: mount /var/lib/kubelet
mkdir -p /var/lib/kubelet
output6=$(mount /dev/$vgName/$lv_kubelet_name /var/lib/kubelet 2>&1)
if [ "$?" != "0" ]; then
  if echo "$output6" |grep "is already mounted";then
    utils_info "already mounted, continue"
  else
    utils_info "disk_init.sh lsblk result:"
    lsblk
    utils_info "disk_init.sh mount -a result:"
    mount -a
    panic "failed to exec [mount /dev/$vgName/$lv_kubelet_name /var/lib/kubelet]: $output6"
  fi
fi

# Step 9: make mount persistent
echo "/dev/$vgName/$lv_container_name /var/lib/${container_runtime} ${file_system} defaults 0 0" >> /etc/fstab
echo "/dev/$vgName/$lv_kubelet_name /var/lib/kubelet ${file_system} defaults 0 0" >> /etc/fstab

utils_info "disk_init success!"