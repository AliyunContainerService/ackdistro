# Getting started

With the following commands, you can quickly install an ACK Distro cluster in an offline environment and experience the same user experience as ACK without reaching the public cloud. You can also check out  [Sealer Get-Started](https://github.com/alibaba/sealer/blob/main/docs/design) for a more comprehensive guide on how to use the cluster.

## Installation

### Install cluster quickly
Get the latest version of sealer：

```bash
wget -c https://sealer.oss-cn-beijing.aliyuncs.com/sealers/sealer-v0.8.5-linux-amd64.tar.gz && \
      tar -xvf sealer-v0.8.5-linux-amd64.tar.gz -C /usr/bin
```

Use sealer to get ACK Distro artifacts and create clusters:

```bash
sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1-20-4-ack-3 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password
```

View cluster status:

```bash
kubectl get cs
```

### [Advanced] Install with production-level configuration

ACK Distro has extensive production-level cluster management experience, and we currently provide the following production-level features:

1. Support automatically manage disk capacity for k8s daemons, to avoid affecting the stability of the OS
2. Support preflight tool, which can determine whether it can be successful before cluster deployment
3. Support cluster health-check tool, which can check whether the cluster is healthy with one click
4. Support etcd backup cronjob, which will run a backup every day at 02:00 by default
5. Support cluster auditing, which only record WRITE request and can use only 1GiB storage to save audit logs for the last 72h on a 3m+3w cluster

#### 1) automatically manage disk capacity for k8s daemons
If you want ACK Distro to better manage the disks it uses, prepare raw data disks as needed (no partitioning and mounting required):

- EtcdDevice: the disk allocated to etcd must be larger than 20GiB and IOPS>3300, only required by the Master node
- StorageDevice: the disk allocated to docker and kubelet, the recommended capacity is greater than 100GiB

Configure your ClusterFile.yaml file:

```yaml
apiVersion: sealer.cloud/v2
kind: Cluster
metadata:
  name: my-cluster
spec:
  image: ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1-20-4-ack-3
  env:
    - PodCIDR=172.45.0.0/16
    - SvcCIDR=10.96.0.0/16
    - StorageDevice=/dev/vdc
    #- DockerRunDiskSize=200 # unit is GiB, capacity for /var/lib/docker
    #- KubeletRunDiskSize=200 # unit is GiB, capacity for /var/lib/kubelet
    #- DNSDomain=cluster.local
    #- ServiceNodePortRange=30000-32767
    #- MTU=1440 # mtu for calico interface, default is 1440
    #- IPAutoDetectionMethod=can-reach=8.8.8.8 # calico ip auto-detection method, default is "can-reach=8.8.8.8", see https://projectcalico.docs.tigera.io/archive/v3.8/reference/node/configuration
    #- SuspendPeriodHealthCheck=false # suspend period health-check, default is false
  ssh:
    passwd: "password"
    #user: root
    #port: "22"
    #pk: /root/.ssh/id_rsa
    #pkPasswd: xxx
  hosts:
    - ips:
        - 1.1.1.1
        - 2.2.2.2
        - 3.3.3.3
      roles: [ master ] # add role field to specify the node role
      env: # rewrite some nodes has different env config
        - EtcdDevice=/dev/vdb
        - StorageDevice=/dev/vde
      # rewrite ssh config if some node has different passwd...
      # ssh:
      #  user: root
      #  passwd: passwd
      #  port: "22"
    - ips:
        - 4.4.4.4
        - 5.5.5.5
      roles: [ node ]
```

```bash
# install
sealer apply -f ClusterFile.yaml
```

#### 2) Use preflight

```bash
# When deploying a cluster, the cluster precheck tool will run by default. If there is a precheck error ErrorX, but you think the error can be ignored, please do as follows
sealer apply -f ClusterFile.yaml --env IgnoreErrors="ErrorX[;ErrorY]"

# Also you can ignore all errors
sealer apply -f ClusterFile.yaml --env IgnoreErrors=all
```

#### 3) Use health check
After the cluster is deployed, health check will be triggered by default, and an error will be reported if the check fails; after that, the health check will run periodically.

```bash
# You can query the health check result of the last run
trident health-check

# Also you can trigger a new check
trident health-check --trigger-all

# more see
trident health-check --help
```

### Operation and maintenance cluster
Expansion node:

```bash
sealer join -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...]
```

Capacity reduction node：

```bash
sealer delete -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...]
```

### Cleanup cluster

```bash
sealer delete -a
```

## Instruction
Please refer to Alibaba Help Center and Kubernetes community for the usage of standard Kubernetes:

- [https://help.aliyun.com/document_detail/309552.html](https://help.aliyun.com/document_detail/309552.html)
- [https://kubernetes.io/#](https://kubernetes.io/#)

### ACK Distro’s recommendation on how to use the network plugin:
[Hybridnet user manual](https://github.com/alibaba/hybridnet/wiki)

### ACK-Distro’s recommendation on how to use the storage plugin:
[Open-local local storage plug-in user manul](https://github.com/alibaba/open-local/blob/main/docs/user-guide/user-guide_zh_CN.md)

### Use ACK to manage ACK-Distro cluster:
[https://help.aliyun.com/document_detail/121053.html](https://help.aliyun.com/document_detail/121053.html)
