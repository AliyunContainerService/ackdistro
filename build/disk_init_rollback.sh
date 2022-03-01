#!/bin/sh
# how to use: `sh disk_init_rollback.sh -d${deviceName}`
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
dev=""
container_runtime=""
while getopts "d:c:" opt; do
  case $opt in
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
    umount /var/lib/kubelet
    umount /var/lib/${container_runtime}/logs
    umount /var/lib/${container_runtime}
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
if [ -z "$dev" ]; then
    info "target device is empty!"
else
    info "wipefs $dev"
    output=$(wipefs -a $dev)
    if [ "$?" != "0" ]; then
        error "failed to exec [wipefs -a $dev]: $output"
        exit 1
    fi
    info "wipefs done!"
fi

info "disk_init_rollback success!"