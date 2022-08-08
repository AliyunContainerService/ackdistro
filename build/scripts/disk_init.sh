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
container_runtime="docker"

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
    container_runtime_size="200"
    utils_info "set partition /var/lib/$container_runtime size to default size - 200G"
fi
if [ -z "$kubelet_size" ]; then
    kubelet_size="200"
    utils_info "set partition /var/lib/kubelet size to default size - 200G"
fi

# Step 2: check whether disk is ok
device_str_arr=(${dev//// })
device_name=${device_str_arr[1]}
part_count=""
if [[ $dev == *"nvme"* ]]; then
    part_count=`lsblk -l|awk '{print $1}'|grep ^$device_name[p0-9]*|wc -l`
else
    part_count=`lsblk -l|awk '{print $1}'|grep ^$device_name[0-9]*|wc -l`
fi
exist_container_runtime_size=""
exist_kubelet_size=""
if [[ $part_count == "0" ]]; then
    panic "$dev does not exist"
elif [[ $part_count == "1" ]]; then
    utils_info "part device $dev"
    # part device
    # remove mount info from /etc/fstab before dd
    sed -i "/\\/var\\/lib\\/kubelet/d"  /etc/fstab
    sed -i "/\\/var\\/lib\\/${container_runtime}/d"  /etc/fstab
    sed -i "/\\/var\\/lib\\/${container_runtime}\\/logs/d"  /etc/fstab

    utils_info "wipefs $dev"
    output0=$(wipefs -a $dev)
    if [ "$?" != "0" ]; then
        panic "failed to exec [wipefs -a $dev]: $output0"
    fi

    all_end=`expr $container_runtime_size + $kubelet_size`
    output1=$(parted $dev mklabel gpt -s 2>&1)
    if [ "$?" != "0" ]; then
        panic "failed to exec [parted $dev mklabel gpt -s]: $output1"
    fi
    output2=$(parted $dev mkpart extended ext4 0 ${container_runtime_size}GiB -s 2>&1)
    if [ "$?" != "0" ]; then
        panic "failed to exec [parted $dev mkpart extended ext4 0 ${docker_size}GiB -s]: $output2"
    fi
    output3=$(parted $dev mkpart extended ext4 ${container_runtime_size}GiB ${all_end}GiB -s 2>&1)
    if [ "$?" != "0" ]; then
        panic "failed to exec [parted $dev mkpart extended ext4 ${docker_size}GiB ${all_end}GiB -s]: $output3"
    fi
    output4=$(parted $dev mkpart extended ext4 ${all_end}GiB 100% -s 2>&1)
    if [ "$?" != "0" ]; then
        panic "failed to exec [parted $dev mkpart extended ext4 ${all_end}GiB 100% -s]: $output4"
    fi
    utils_info "parted done!"
elif [[ $part_count == "2" ]]; then
    part=""
    if [[ $dev == *"nvme"* ]]; then
        part=`lsblk -l|awk '{print $1}'|grep ^$device_name[p0-9]`
    else
        part=`lsblk -l|awk '{print $1}'|grep ^$device_name[0-9]`
    fi
    panic "$dev has been parted already, but NOT in correct way: only one partition $part found"
else
    utils_info "$dev has been parted already"
    # check mountpoint
    if [[ $dev == *"nvme"* ]]; then
        mount |grep ^$dev[p0-9]*|grep /var/lib/kubelet
        if [ "$?" != "0" ]; then
            panic "no mountpoint /var/lib/kubelet found!"
        fi
        mount |grep ^$dev[p0-9]*|grep /var/lib/${container_runtime}
        if [ "$?" != "0" ]; then
            panic "no mountpoint /var/lib/${container_runtime} found!"
        fi
    else
        mount |grep ^$dev[0-9]*|grep /var/lib/kubelet
        if [ "$?" != "0" ]; then
            panic "no mountpoint /var/lib/kubelet found!"
        fi
        mount |grep ^$dev[0-9]*|grep /var/lib/${container_runtime}
        if [ "$?" != "0" ]; then
            panic "no mountpoint /var/lib/${container_runtime} found!"
        fi
    fi
    utils_info "$dev has been mounted already, and in correct way~"

    # check partition size
    exist_container_runtime_size=""
    exist_kubelet_size=""
    # $1,$4,$7 = device,size,mountpoint
    if [[ $dev == *"nvme"* ]]; then
        exist_container_runtime_size=`lsblk -l|awk '{print $1,$4,$7}'|grep ^$device_name[p0-9]*|grep /var/lib/${container_runtime}|awk '{print $2}'`
        exist_kubelet_size=`lsblk -l|awk '{print $1,$4,$7}'|grep ^$device_name[p0-9]*|grep /var/lib/kubelet|awk '{print $2}'`
    else
        exist_container_runtime_size=`lsblk -l|awk '{print $1,$4,$7}'|grep ^$device_name[0-9]*|grep /var/lib/${container_runtime}|awk '{print $2}'`
        exist_kubelet_size=`lsblk -l|awk '{print $1,$4,$7}'|grep ^$device_name[0-9]*|grep /var/lib/kubelet|awk '{print $2}'`
    fi
    exist_container_runtime_size=${exist_container_runtime_size%G*}
    exist_kubelet_size=${exist_kubelet_size%G*}
    re='^[0-9]+$'
    if ! [[ $exist_container_runtime_size =~ $re ]] ; then
        panic "$exist_container_runtime_size is not a number, we only support G"
    fi
    if ! [[ $exist_kubelet_size =~ $re ]] ; then
        panic "$exist_container_runtime_size is not a number, we only support G"
    fi

    if [[ $exist_container_runtime_size -lt $container_runtime_size ]]; then
        panic "$dev has been mounted already, but size of /var/lib/${container_runtime} is $exist_container_runtime_size, we want $container_runtime_size!"
    fi
    if [[ $exist_kubelet_size -lt $kubelet_size ]]; then
        panic "$dev has been mounted already, but size of /var/lib/kubelet is $exist_kubelet_size, we want $kubelet_size!"
    fi
    utils_info "$dev has been parted already, and in correct way~"
    exit 0
fi

# sleep a little while
sleep 1s

# Step 3: umount before mkfs
umount /var/lib/kubelet
umount /var/lib/${container_runtime}/logs
umount /var/lib/${container_runtime}

# Step 4: make filesystem
if [[ $dev == *"nvme"* ]]; then
    mkfs.ext4 -F ${dev}p1
    mkfs.ext4 -F ${dev}p2
else
    mkfs.ext4 -F ${dev}1
    mkfs.ext4 -F ${dev}2
fi
utils_info "mkfs done!"

# Step 5: umount before mount
umount /var/lib/kubelet
umount /var/lib/${container_runtime}/logs
umount /var/lib/${container_runtime}

# Step 6: mount /var/lib/${container_runtime}
mkdir -p /var/lib/${container_runtime}
if [[ $dev == *"nvme"* ]]; then
    output5=$(mount ${dev}p1 /var/lib/${container_runtime} 2>&1)
    if [ "$?" != "0" ]; then
        utils_info "disk_init.sh lsblk result:"
        lsblk
        utils_info "disk_init.sh mount -a result:"
        mount -a
        panic "failed to exec [mount ${dev}p1 /var/lib/docker]: $output5"
    fi
else
    output5=$(mount ${dev}1 /var/lib/${container_runtime} 2>&1)
    if [ "$?" != "0" ]; then
        utils_info "disk_init.sh lsblk result:"
        lsblk
        utils_info "disk_init.sh mount -a result:"
        mount -a
        panic "failed to exec [mount ${dev}1 /var/lib/docker]: $output5"
    fi
fi
mkdir -p /var/lib/${container_runtime}/logs

# Step 7: mount /var/lib/kubelet
mkdir -p /var/lib/kubelet
if [[ $dev == *"nvme"* ]]; then
    output6=$(mount ${dev}p2 /var/lib/kubelet 2>&1)
    if [ "$?" != "0" ]; then
        utils_info "disk_init.sh lsblk result:"
        lsblk
        utils_info "disk_init.sh mount -a result:"
        mount -a
        panic "failed to exec [mount ${dev}p2 /var/lib/kubelet]: $output6"
    fi
else
    output6=$(mount ${dev}2 /var/lib/kubelet 2>&1)
    if [ "$?" != "0" ]; then
        utils_info "disk_init.sh lsblk result:"
        lsblk
        utils_info "disk_init.sh mount -a result:"
        mount -a
        panic "failed to exec [mount ${dev}2 /var/lib/kubelet]: $output6"
    fi
fi

# Step 8: make mount persistent
if [[ $dev == *"nvme"* ]]; then
    echo "${dev}p1 /var/lib/${container_runtime} ext4 defaults 0 0" >> /etc/fstab
    echo "${dev}p2 /var/lib/kubelet ext4 defaults 0 0" >> /etc/fstab
else
    echo "${dev}1 /var/lib/${container_runtime} ext4 defaults 0 0" >> /etc/fstab
    echo "${dev}2 /var/lib/kubelet ext4 defaults 0 0" >> /etc/fstab
fi

utils_info "disk_init success!"