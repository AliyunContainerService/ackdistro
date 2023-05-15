#!/bin/sh

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

# how to use: `sh disk_init_rollback.sh -d${deviceName}`
set -x

clean_vg_pool()
{
    vgNameKeywordToDelete="$1"
    vgNameKeywordToRetain="$2"

    # step 1: get yoda pvlist and vglist
    if [ "$vgNameKeywordToRetain" != "" ];then
        pvs=`pvs | grep $vgNameKeywordToDelete | grep -v $vgNameKeywordToRetain | awk '{print $1}'`
        vgs=`vgs | grep $vgNameKeywordToDelete | grep -v $vgNameKeywordToRetain | awk '{print $1}'`
    else
        pvs=`pvs | grep $vgNameKeywordToDelete | awk '{print $1}'`
        vgs=`vgs | grep $vgNameKeywordToDelete | awk '{print $1}'`
    fi
    c=0
    pvlist=()
    vglist=()
    for v in $pvs
    do
        pvlist[$c]=$v
        c=$[c+1]
    done
    c=0
    for v in $vgs
    do
        vglist[$c]=$v
        c=$[c+1]
    done
    # step 2: vgremove first
    for value in ${vglist[*]}
    do
        echo "vgremove $value"
        suc=false
        for i in `seq 1 6`;do
          vgremove -f $value
          if [ "$?" = "0" ]; then
            suc=true
            break
          fi
          sleep 5
        done
        if [ "$suc" != "true" ];then
          panic "failed to do vgremove, please run (vgremove -f $value) by yourself"
        fi
    done
    # step 3: pvremove
    for value in ${pvlist[*]}
    do
        echo "pvremove $value"
        pvremove -f $value
        if [ "$?" != "0" ]; then
          sleep 5; pvremove -f $value
        fi
    done
}

clean_yoda_lv() {
  vgs=$(vgdisplay -s|awk '{print $1}'|tr -d '"')
  echo $vgs
  for i in "${vgs[@]}"; do
      echo "vg is $i"
      lvs1=$(lvscan|awk '/\/dev\/'$i'\/yoda/{print $2}'|tr -d "\'")
      for j in "${lvs1[@]}"; do
          if [ "$j" == "" ];then
              continue
          fi
          lvremove -f $j
      done

      lvs2=$(lvscan|awk '/\/dev\/'$i'\/csi/{print $2}'|tr -d "\'")
      for j in "${lvs2[@]}"; do
          if [ "$j" == "" ];then
              continue
          fi
          lvremove -f $j
      done
  done
}

# Step 0: lsblk check
utils_info "disk_init_rollback.sh lsblk result:"
lsblk

# Step 1: get device
etcdDev=${EtcdDevice}
storageDev=${StorageDevice}
storageVGName=${StorageVGName}
container_runtime=${ContainerRuntime:-docker}
extraMountPointsArray=`utils_split_str_to_array ${ExtraMountPoints}`
extraMountPointsRecyclePolicy=${ExtraMountPointsRecyclePolicy:-Retain}

containerStorage=${ContainerDataRoot:-/var/lib/${container_runtime}}

if utils_no_need_mkfs $storageDev; then
  echo "no need to mkfs for storage device $storageDev"
else
  utils_is_device_array $storageDev || panic "invalid input device name $storageDev, it must be /dev/***[,/dev/***]"
  vgName=$defaultVgName
  if [ "$VGPoolName" != "" ];then
    vgName=$VGPoolName
  fi
fi

if [ "$storageVGName" != "" ];then
  if [ "$storageDev" != "" ];then
    panic "only one of StorageDevice or StorageVGName should be specified"
  fi
  utils_is_vgname $storageVGName || panic "invalid vgname $storageVGName"
  vgName=$storageVGName
fi

reg="^\/(\w+\/?)+:[0-9]+$"
for mp in $extraMountPointsArray;do
  if [[ $mp =~ $reg ]];then
    continue
  else
    panic "invalid ExtraMountPoints: $ExtraMountPoints, it must be /path1:size1,/path2:size2"
  fi
done

# Step 2: clean mount info in /etc/fstab
if ! utils_no_need_mkfs $etcdDev;then
  sed -i "/\\/var\\/lib\\/etcd/d"  /etc/fstab

  # umount etcd
  suc=false
  for i in `seq 1 10`;do
      sleep 1s
      umount /var/lib/etcd
      if findmnt /var/lib/etcd;then
          continue
      fi
      suc=true
      break
  done
  if [ "$suc" != "true" ];then
      panic "failed to umount [/var/lib/etcd], some unknown error occurs, please run [umount /var/lib/etcd] on that node by yourself."
  fi
  utils_info "umount etcd done!"
fi

if ! utils_no_need_mkfs $storageDev || [ "$storageVGName" != "" ];then
  sed -i "/\\/var\\/lib\\/kubelet/d"  /etc/fstab
  sed -i "\#${containerStorage}#d"  /etc/fstab
  if [ "$ExtraMountPoints" != "" ] && [ "$extraMountPointsRecyclePolicy" == "Delete" ];then
    sed -i "/${extraMountPointAnno}/d" /etc/fstab
  fi

  # umount kubelet/docker
  suc=false
  for i in `seq 1 10`;do
      sleep 1s
      for km in `mount -l |grep "/var/lib/kubelet/pods" |awk '{print $3}'`;do
        umount $km;
      done

      if [ "${container_runtime}" == "containerd" ];then
        for cm in `mount | grep ^overlay | grep lowerdir=/var/lib/containerd | awk '{print $3}'`;do
          umount $cm;
        done
      fi
      umount /var/lib/kubelet
      umount ${containerStorage}
      if findmnt /var/lib/kubelet;then
          continue
      fi
      if findmnt ${containerStorage};then
          continue
      fi

      if [ "$ExtraMountPoints" != "" ] && [ "$extraMountPointsRecyclePolicy" == "Delete" ];then
        _lv_i=0
        for _mp_sz in $extraMountPointsArray;do
          _lv_name=${extraLVNamePrefix}${_lv_i}
          umount /dev/$vgName/${_lv_name}
          if findmnt /dev/$vgName/${_lv_name};then
            continue 2
          fi

          let _lv_i=_lv_i+1
        done
      fi

      suc=true
      break
  done
  if [ "$suc" != "true" ];then
      panic "failed to umount [/var/lib/kubelet ${containerStorage}], some unknown error occurs, please run [umount /var/lib/kubelet;umount ${containerStorage}] on that node by yourself."
  fi
  utils_info "umount done!"
fi

# Step 3: clean ackdistro pool
if ! utils_no_need_mkfs $storageDev;then
  if [ "$ExtraMountPoints" == "" ] || [ "$extraMountPointsRecyclePolicy" == "Delete" ];then
    clean_vg_pool $vgName

    for temp in `utils_split_str_to_array $storageDev`;do
        utils_info "wipefs $temp"
        output=$(wipefs -a $temp)
        if [ "$?" != "0" ]; then
            echo -e "\033[1;31mPanic error: failed to exec [wipefs -a $temp]: $output, please check this panic\033[0m"
        fi
        utils_info "wipefs $temp done!"
    done
  fi
elif [ "$storageVGName" != "" ];then
  lv_container_name="container"
  lv_kubelet_name="kubelet"
  lvremove /dev/$vgName/$lv_container_name -y
  lvremove /dev/$vgName/$lv_kubelet_name -y
  if [ "$ExtraMountPoints" != "" ] && [ "$extraMountPointsRecyclePolicy" == "Delete" ];then
    _lv_i=0
    for _mp_sz in $extraMountPointsArray;do
      _lv_name=${extraLVNamePrefix}${_lv_i}
      lvremove /dev/$vgName/${_lv_name} -y

      let _lv_i=_lv_i+1
    done
  fi
fi

# Step 4: clean yoda pools
clean_yoda_lv

clean_vg_pool "yoda-pool" $vgName

# Step 5: wipe etcd device
if utils_no_need_mkfs $etcdDev; then
    utils_info "target etcd device is empty!"
else
    utils_info "wipefs $etcdDev"
    output=$(wipefs -a $etcdDev)
    if [ "$?" != "0" ]; then
        panic "failed to exec [wipefs -a $etcdDev]: $output"
    fi
    utils_info "wipefs $etcdDev done!"
fi

utils_info "disk_init_rollback success!"