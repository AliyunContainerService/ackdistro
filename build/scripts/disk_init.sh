#!/bin/sh
# how to use: `sh disk_init.sh -d${deviceName}`
set -x

error()
{
    set +x
    echo "##TRIDENT_EXEC_RESULT_BEGIN##"$@"##TRIDENT_EXEC_RESULT_END##"
    echo -e "\033[1;31m$@\033[0m"
    set -x
}

info()
{
    echo -e "\033[1;32m$@\033[0m"
}

shouldMkFs() {
    if [ "$1" != "" ] && [ "$1" != "/" ] && [ "$1" != "\"/\"" ];then
        return 0
    fi
    return 1
}

# Step 0: get device and parts size
dev=""
etcdDev=""
container_runtime_size=""
kubelet_size=""
container_runtime="docker"
while getopts "d:a:b:c:" opt; do
  case $opt in
    e)
      etcdDev=$OPTARG
      info "The target etcd device: $OPTARG"
      ;;
    d)
      dev=$OPTARG
      info "The target device: $OPTARG"
      ;;
    a)
      container_runtime_size=$OPTARG
      info "Container runtime size: $OPTARG"
      ;;
    b)
      kubelet_size=$OPTARG
      info "Kubelet size: $OPTARG"
      ;;
    c)
      container_runtime=$OPTARG
      info "Container runtime: $OPTARG"
      ;;
    \?)
      error "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

# Step 0: init etcd device
if shouldMkFs $etcdDev;then
    set -e
    umount /var/lib/etcd
    mkfs.ext4 -F $etcdDev
    mkdir -p /var/lib/etcd
    mount $etcdDev /var/lib/etcd
    now=`date +'%Y-%m-%d-%H-%M-%S'`
    cp -r /var/lib/etcd/ /tmp/etcd-data-backup-${now}
    rm -rf /var/lib/etcd/*
    echo "$etcdDev /var/lib/etcd ext4 defaults 0 0" >> /etc/fstab
    set +e
fi

# Step 1: check val
if ! shouldMkFs $dev; then
    info "device is empty! exit..."
    exit 0
fi
if [ -z "$container_runtime_size" ]; then
    container_runtime_size="200"
    info "set partition /var/lib/$container_runtime size to default size - 200G"
fi
if [ -z "$kubelet_size" ]; then
    kubelet_size="200"
    info "set partition /var/lib/kubelet size to default size - 200G"
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
    error "$dev does not exist"
    exit 1
elif [[ $part_count == "1" ]]; then
    info "part device $dev"
    # part device
    # remove mount info from /etc/fstab before dd
    sed -i "/\\/var\\/lib\\/kubelet/d"  /etc/fstab
    sed -i "/\\/var\\/lib\\/${container_runtime}/d"  /etc/fstab
    sed -i "/\\/var\\/lib\\/${container_runtime}\\/logs/d"  /etc/fstab

    info "wipefs $dev"
    output0=$(wipefs -a $dev)
    if [ "$?" != "0" ]; then
        error "failed to exec [wipefs -a $dev]: $output0"
        exit 1
    fi

    all_end=`expr $container_runtime_size + $kubelet_size`
    output1=$(parted $dev mklabel gpt -s 2>&1)
    if [ "$?" != "0" ]; then
        error "failed to exec [parted $dev mklabel gpt -s]: $output1"
        exit 1
    fi
    output2=$(parted $dev mkpart extended ext4 0 ${container_runtime_size}GiB -s 2>&1)
    if [ "$?" != "0" ]; then
        error "failed to exec [parted $dev mkpart extended ext4 0 ${docker_size}GiB -s]: $output2"
        exit 1
    fi
    output3=$(parted $dev mkpart extended ext4 ${container_runtime_size}GiB ${all_end}GiB -s 2>&1)
    if [ "$?" != "0" ]; then
        error "failed to exec [parted $dev mkpart extended ext4 ${docker_size}GiB ${all_end}GiB -s]: $output3"
        exit 1
    fi
    output4=$(parted $dev mkpart extended ext4 ${all_end}GiB 100% -s 2>&1)
    if [ "$?" != "0" ]; then
        error "failed to exec [parted $dev mkpart extended ext4 ${all_end}GiB 100% -s]: $output4"
        exit 1
    fi
    info "parted done!"
elif [[ $part_count == "2" ]]; then
    part=""
    if [[ $dev == *"nvme"* ]]; then
        part=`lsblk -l|awk '{print $1}'|grep ^$device_name[p0-9]`
    else
        part=`lsblk -l|awk '{print $1}'|grep ^$device_name[0-9]`
    fi
    error "$dev has been parted already, but NOT in correct way: only one partition $part found"
    exit 1
else
    info "$dev has been parted already"
    # check mountpoint
    if [[ $dev == *"nvme"* ]]; then
        mount |grep ^$dev[p0-9]*|grep /var/lib/kubelet
        if [ "$?" != "0" ]; then
            error "no mountpoint /var/lib/kubelet found!"
            exit 1
        fi
        mount |grep ^$dev[p0-9]*|grep /var/lib/${container_runtime}
        if [ "$?" != "0" ]; then
            error "no mountpoint /var/lib/${container_runtime} found!"
            exit 1
        fi
    else
        mount |grep ^$dev[0-9]*|grep /var/lib/kubelet
        if [ "$?" != "0" ]; then
            error "no mountpoint /var/lib/kubelet found!"
            exit 1
        fi
        mount |grep ^$dev[0-9]*|grep /var/lib/${container_runtime}
        if [ "$?" != "0" ]; then
            error "no mountpoint /var/lib/${container_runtime} found!"
            exit 1
        fi
    fi
    info "$dev has been mounted already, and in correct way~"

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
        error "$exist_container_runtime_size is not a number, we only support G"
        exit 1
    fi
    if ! [[ $exist_kubelet_size =~ $re ]] ; then
        error "$exist_container_runtime_size is not a number, we only support G"
        exit 1
    fi

    if [[ $exist_container_runtime_size -lt $container_runtime_size ]]; then
        error "$dev has been mounted already, but size of /var/lib/${container_runtime} is $exist_container_runtime_size, we want $container_runtime_size!"
        exit 1
    fi
    if [[ $exist_kubelet_size -lt $kubelet_size ]]; then
        error "$dev has been mounted already, but size of /var/lib/kubelet is $exist_kubelet_size, we want $kubelet_size!"
        exit 1
    fi
    info "$dev has been parted already, and in correct way~"
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
info "mkfs done!"

# Step 5: umount before mount
umount /var/lib/kubelet
umount /var/lib/${container_runtime}/logs
umount /var/lib/${container_runtime}

# Step 6: mount /var/lib/${container_runtime}
mkdir -p /var/lib/${container_runtime}
if [[ $dev == *"nvme"* ]]; then
    output5=$(mount ${dev}p1 /var/lib/${container_runtime} 2>&1)
    if [ "$?" != "0" ]; then
        info "disk_init.sh lsblk result:"
        lsblk
        info "disk_init.sh mount -a result:"
        mount -a
        error "failed to exec [mount ${dev}p1 /var/lib/docker]: $output5"
        exit 1
    fi
else
    output5=$(mount ${dev}1 /var/lib/${container_runtime} 2>&1)
    if [ "$?" != "0" ]; then
        info "disk_init.sh lsblk result:"
        lsblk
        info "disk_init.sh mount -a result:"
        mount -a
        error "failed to exec [mount ${dev}1 /var/lib/docker]: $output5"
        exit 1
    fi
fi
mkdir -p /var/lib/${container_runtime}/logs

# Step 7: mount /var/lib/kubelet
mkdir -p /var/lib/kubelet
if [[ $dev == *"nvme"* ]]; then
    output6=$(mount ${dev}p2 /var/lib/kubelet 2>&1)
    if [ "$?" != "0" ]; then
        info "disk_init.sh lsblk result:"
        lsblk
        info "disk_init.sh mount -a result:"
        mount -a
        error "failed to exec [mount ${dev}p2 /var/lib/kubelet]: $output6"
        exit 1
    fi
else
    output6=$(mount ${dev}2 /var/lib/kubelet 2>&1)
    if [ "$?" != "0" ]; then
        info "disk_init.sh lsblk result:"
        lsblk
        info "disk_init.sh mount -a result:"
        mount -a
        error "failed to exec [mount ${dev}2 /var/lib/kubelet]: $output6"
        exit 1
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

info "disk_init success!"