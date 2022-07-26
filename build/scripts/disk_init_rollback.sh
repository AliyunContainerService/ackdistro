#!/bin/sh

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

# how to use: `sh disk_init_rollback.sh -d${deviceName}`
set -x

# remove the containers and images
docker ps -aq | xargs -I '{}' docker stop {}
docker ps -aq | xargs -I '{}' docker rm {}
docker image ls -aq | xargs -I '{}' docker image rm {}

# kill dockerd process and related processes
for pid in $(ps aux | awk '{ if ($11 == "dockerd" || $11 == "containerd" || $11 == "containerd-shim") print $2 }')
do
  kill -9 ${pid}
done
for pid in $(ps aux | awk '{ if (match($11, ".*/dockerd$$") || match($11, ".*/containerd$$") || match($11, ".*/containerd-shim$$")) print $2 }')
do
  kill -9 ${pid}
done

# umount and clean the docker related directories
rm -rf /var/lib/docker/*

clean_yoda_pool()
{
    # step 1: get yoda pvlist and vglist
    pvs=`pvs|grep yoda-pool|awk '{print $1}'`
    vgs=`vgs|grep yoda-pool|awk '{print $1}'`
    c=0
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
        vgremove -f $value
    done
    # step 3: pvremove
    for value in ${pvlist[*]}
    do
        echo "pvremove $value"
        pvremove -f $value
    done
}

# Step 0: lsblk check
utils_info "disk_init_rollback.sh lsblk result:"
lsblk

# Step 1: get device
etcdDev=${EtcdDevice}
dev=${StorageDevice}
container_runtime="docker"

# Step 2: clean yoda pools
clean_yoda_pool

# Step 3: clean mount info in /etc/fstab
sed -i "/\\/var\\/lib\\/etcd/d"  /etc/fstab
sed -i "/\\/var\\/lib\\/kubelet/d"  /etc/fstab
sed -i "/\\/var\\/lib\\/${container_runtime}/d"  /etc/fstab
sed -i "/\\/var\\/lib\\/${container_runtime}\\/logs/d"  /etc/fstab

# Step 4: umount
suc=false
for i in `seq 1 10`;do
    sleep 1s
    for km in `mount -l |grep "/var/lib/kubelet/pods" |awk '{print $3}'`;do
      umount $km;
    done
    umount /var/lib/etcd
    umount /var/lib/kubelet
    umount /var/lib/${container_runtime}/logs
    umount /var/lib/${container_runtime}
    if findmnt /var/lib/etcd;then
        continue
    fi
    if findmnt /var/lib/kubelet;then
        continue
    fi
    if findmnt /var/lib/${container_runtime};then
        continue
    fi
    if findmnt /var/lib/${container_runtime}/logs;then
        continue
    fi
    suc=true
    break
done
if [ "$suc" != "true" ];then
    panic "failed to umount [/var/lib/kubelet /var/lib/docker], some unknown error occurs, please run [umount /var/lib/kubelet;umount /var/lib/docker;umount /var/lib/docker/logs] on that node by yourself."
fi
utils_info "umount done!"

# Step 5: wipefs
if ! utils_shouldMkFs $dev; then
    utils_info "target device is empty!"
else
    utils_info "wipefs $dev"
    output=$(wipefs -a $dev)
    if [ "$?" != "0" ]; then
        panic "failed to exec [wipefs -a $dev]: $output"
    fi
    utils_info "wipefs $dev done!"
fi

if ! utils_shouldMkFs $etcdDev; then
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