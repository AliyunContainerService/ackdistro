#!/bin/sh

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

# how to use: `sh disk_init.sh -d${deviceName}`
set -x

# Step 0: get device and parts size
storageDev=${StorageDevice}
storageVGName=${StorageVGName}
etcdDev=${EtcdDevice}
container_runtime_size=${DockerRunDiskSize}
kubelet_size=${KubeletRunDiskSize}
file_system=${DaemonFileSystem}
container_runtime=${ContainerRuntime}
extraMountPointsArray=`utils_split_str_to_array ${ExtraMountPoints}`

if [ "$container_runtime" == "" ];then
  container_runtime=docker
fi

if [ -z "$file_system" ]; then
    file_system="ext4"
    utils_info "set file system to default value - ${file_system}"
fi

if utils_no_need_mkfs $storageDev; then
  echo "no need to mkfs for storage device $storageDev"
else
  utils_is_device_array $storageDev || panic "invalid input device name $storageDev, it must be /dev/***[,/dev/***]"
fi

if [ "$storageVGName" != "" ];then
  if [ "$storageDev" != "" ];then
    panic "only one of StorageDevice or StorageVGName should be specified"
  fi
  utils_is_vgname $storageVGName || panic "invalid vgname $storageVGName"
fi

reg="^\/(\w+\/?)+:[0-9]+$"
for mp in $extraMountPointsArray;do
  if [[ $mp =~ $reg ]];then
    continue
  else
    panic "invalid ExtraMountPoints: $ExtraMountPoints, it must be /path1:size1,/path2:size2"
  fi
done

mkfsForce() {
    if [ "$file_system" = "ext4" ];then
        mkfs.ext4 -F "$1"
    elif [ "$file_system" = "xfs" ];then
        mkfs.xfs -f "$1"
    else
        panic "file system $file_system is not supported now"
    fi
}

checkMountOK() {
    mountPoint=${1}
    nowDev=`mount | awk -v mp="$mountPoint" '{if($3 == mp)print $1}'`
    if [ "${nowDev}" != "" ];then
        utils_info "${mountPoint} has already been mounted by ${nowDev}"
        return 0
    fi

    return 1
}

mountEtcd() {
    if checkMountOK /var/lib/etcd;then
        return 0
    fi

    mkfsForce $etcdDev
    mkdir -p /var/lib/etcd
    output=$(mount $etcdDev /var/lib/etcd 2>&1); [[ $? -ne 0 ]] && panic "failed to mount $etcdDev: $output"
    now=`date +'%Y-%m-%d-%H-%M-%S'`
    cp -r /var/lib/etcd/ /tmp/etcd-data-backup-${now}
    output=$(rm -rf /var/lib/etcd/* 2>&1); [[ $? -ne 0 ]] && panic "failed to rm /var/lib/etcd/*: $output"
    echo "$etcdDev /var/lib/etcd ${file_system} defaults 0 0" >> /etc/fstab
}

createLv() {
  _lvname=$1
  _lvsize=$2
  _vgname=$3
  lvs|grep $_lvname
  if [ "$?" == "0" ]; then
    utils_info "lv $_lvname exists!"
    return 0
  fi

  suc=false
  for i in `seq 1 12`;do
    if [ "$i" != "1" ];then
        sleep 5
    fi
    lvcreate --name $_lvname --size ${_lvsize}"Gi" $_vgname -y 2>&1
    if [ "$?" == "0" ]; then
        suc=true
        break
    fi
  done
  if [ "$suc" != "true" ]; then
    return 1
  fi
  return 0
}

# Step 0: init etcd device
if ! utils_no_need_mkfs $etcdDev;then
    mountEtcd
fi

# Step 1: check val
if utils_no_need_mkfs $storageDev && [ "$storageVGName" == "" ]; then
    utils_info "device and vg name is empty! exit..."
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

containerStorage=${ContainerDataRoot:-/var/lib/${container_runtime}}

checkMountOK /var/lib/kubelet
check1=$?
checkMountOK $containerStorage
check2=$?
if [ "${check1}" == "0" ] && [ "${check2}" == "0" ];then
    exit 0
fi
if [ "${check1}" == "0" ] && [ "${check2}" != "0" ];then
    panic "mount for /var/lib/kubelet found, but not ${containerStorage}, if you are scaling this node and some error occurs before, you can try delete it and try again"
fi
if [ "${check1}" != "0" ] && [ "${check2}" == "0" ];then
    panic "mount for ${containerStorage} found, but not /var/lib/kubelet, if you are scaling this node and some error occurs before, you can try delete it and try again"
fi

# Step 2: create vg
if ! utils_no_need_mkfs $storageDev;then
    vgName=$defaultVgName
    if [ "$VGPoolName" != "" ];then
        vgName=$VGPoolName
    fi
    for temp in `utils_split_str_to_array $storageDev`;do
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
elif [ "$storageVGName" != "" ];then
    vgName=$storageVGName
fi

# Step 3: create lv
sed -i "/\\/var\\/lib\\/kubelet/d" /etc/fstab
sed -i "/\\/var\\/lib\\/${container_runtime}/d" /etc/fstab
sed -i "/${extraMountPointAnno}/d" /etc/fstab

lv_container_name="container"
lv_kubelet_name="kubelet"

createLv $lv_container_name $container_runtime_size $vgName || panic "failed to create $lv_container_name lv, please see log above"

createLv $lv_kubelet_name $kubelet_size $vgName || panic "failed to create $lv_kubelet_name lv, please see log above"

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
    panic "failed to exec [mount /dev/$vgName/$lv_container_name /var/lib/${container_runtime}]: $output5"
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

_lv_i=0
for _mp_sz in $extraMountPointsArray;do
  _mp=${_mp_sz%:*}
  _sz=${_mp_sz#*:}

  if ! checkMountOK $_mp;then
    _lv_name=${extraLVNamePrefix}${_lv_i}
    createLv ${_lv_name} $_sz $vgName || panic "failed to create ${_lv_name} lv, please see log above"

    sleep 1s
    #umount before mkfs
    umount $_mp
    if [ "$?" != "0" ]; then
      utils_info "failed to umount, maybe you should clean this node before join"
    fi

    if ! blkid|grep $_lv_name|grep ${file_system}; then
      # This func will exit when fail
      mkfsForce /dev/$vgName/$_lv_name
    else
      utils_info "lv /dev/$vgName/$_lv_name has file system"
    fi

    #umount before mount
    umount $_mp
    if [ "$?" != "0" ]; then
      utils_info "failed to umount, maybe you should clean this node before join"
    fi

    systemctl daemon-reexec

    mkdir -p $_mp
    output=$(mount /dev/$vgName/${_lv_name} $_mp 2>&1)
    if [ "$?" != "0" ]; then
      if echo "$output" |grep "is already mounted";then
        utils_info "already mounted, continue"
      else
        utils_info "disk_init.sh lsblk result:"
        lsblk
        utils_info "disk_init.sh mount -a result:"
        mount -a
        panic "failed to exec [mount /dev/$vgName/$_lv_name $_mp]: $output"
      fi
    fi
  fi

  echo "/dev/$vgName/$_lv_name $_mp ${file_system} defaults 0 0 $extraMountPointAnno" >> /etc/fstab

  let _lv_i=_lv_i+1
done

utils_info "disk_init success!"