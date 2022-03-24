#!/bin/sh
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
info "disk_init_rollback.sh lsblk result:"
lsblk

# Step 1: get device
etcdDev=""
dev=""
container_runtime="docker"
while getopts "d:c:e:" opt; do
  case $opt in
    e)
      etcdDev=$OPTARG
      info "The target etcd device: $OPTARG"
      ;;
    d)
      dev=$OPTARG
      info "The target device: $OPTARG"
      ;;
    c):
      container_runtime=$OPTARG
      green "The container runtime: $OPTARG"
      ;;
    \?)
      error "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

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
    error "failed to umount [/var/lib/kubelet /var/lib/docker], some unknown error occurs, please run [umount /var/lib/kubelet;umount /var/lib/docker;umount /var/lib/docker/logs] on that node by yourself."
    exit 1
fi
info "umount done!"

# Step 5: wipefs
if ! shouldMkFs $dev; then
    info "target device is empty!"
else
    info "wipefs $dev"
    output=$(wipefs -a $dev)
    if [ "$?" != "0" ]; then
        error "failed to exec [wipefs -a $dev]: $output"
        exit 1
    fi
    info "wipefs $dev done!"
fi

if ! shouldMkFs $etcdDev; then
    info "target etcd device is empty!"
else
    info "wipefs $etcdDev"
    output=$(wipefs -a $etcdDev)
    if [ "$?" != "0" ]; then
        error "failed to exec [wipefs -a $etcdDev]: $output"
        exit 1
    fi
    info "wipefs $etcdDev done!"
fi

info "disk_init_rollback success!"