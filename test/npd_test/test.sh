# 缺少测试用例：
# ● inode 压力测试(P1)
# ● IO 带宽测试
# ● OOM，这个是要 kernel 的，但是测试用例中 done
# ● 内核死锁
# ● 内核 bug
# ● 内核 panic
# ● 节点内存条未装配
# ● 节点的 docker/kubelet 测试用例，并测试效果

nodename=$2
IP=$3

# ● 内核死锁 KernelDeadlock; 包含AUFSUmountHung、DockerHung
function test_AUFS_unmount_hung() {
    cmd="echo 'kernel: BUG: task umount:11451 blocked for more than 300 seconds.' >> /dev/kmsg"
    exec_cmd cmd
}

function test_docker_hung() {
    cmd="echo 'kernel: INFO: task docker:20744 blocked for more than 120 seconds.' >> /dev/kmsg"
    exec_cmd cmd
}

# ● 内核 bug 内核 panic
function test_kernel_bug() {

}

# ● 节点的 docker/kubelet 测试用例，并测试效果
function test_kernel_docker() {
    cmd="systemctl stop docker"
    exec_cmd cmd
}

function test_kernel_kubelet() {
    cmd="systemctl stop kubelet"
    exec_cmd cmd
}

function test_fd_pressure() {
    gcc -o fd_pressure fd_pressure.c
}

function test_pid_pressure() {
    gcc -o pid_pressure pid_pressure.c
}

function test_oom() {
    cmd="echo 'kernel: BUG: Kill process 29957 (java) score 366 or sacrifice child' >> /dev/kmsg"
    exec_cmd cmd
}

function test_task_hung() {
    cmd="echo 'kernel: INFO: task java:xxx blocked for more than 120 seconds.' >> /dev/kmsg"
    exec_cmd cmd
}

function test_unregister_netdevice() {
    cmd="echo 'kernel: BUG: unregister_netdevice: waiting for veth31bce17 to become free. Usage count = 1' >> /dev/kmsg"
    exec_cmd cmd
}

function test_kerneloops() {
    cmd="echo 'kernel: BUG: unable to handle kernel NULL pointer dereference at TESTING' >> /dev/kmsg"
    exec_cmd cmd
}

function test_cpu_softlockerr() {
    cmd="echo 'kernel: BUG: soft lockup' >> /dev/kmsg"
    exec_cmd cmd
}

function test_cpu_hardlockerr() {
    cmd="echo 'kernel: BUG: NMI watchdog: Watchdog detected hard LOCKUP' >> /dev/kmsg"
    exec_cmd cmd
}

function test_disk_umount() {
    cmd="echo 'kernel: BUG: Remounting filesystem read-only' >> /dev/kmsg"
    exec_cmd cmd
}

function test_cpu_temperature_high() {
    cmd="echo 'kernel: BUG: temperature above threshold' >> /dev/kmsg"
    exec_cmd cmd
}

function test_irqbalance() {
    cmd="systemctl stop irqbalance"
    exec_cmd cmd
}

function exec_cmd() {
    if [[ -z $IP ]];
    then
        sudo sh -c $cmd
    else
        ssh root@${IP} $cmd
}

function get_node_conditions() {
    if [[ -n $nodename ]];
    then
        kubectl describe node ${nodename} | grep Conditions -A 30 | grep True
    fi
}

function test_demo() {
    echo "demo"
}

function main() {
    testOption=$1
    test_$testOption
}



