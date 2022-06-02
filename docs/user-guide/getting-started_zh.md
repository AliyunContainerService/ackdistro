# 开始

## 安装方法
通过以下Sealer指令，您可以快速地在离线环境搭建一套ACK Distro集群，无需到达公有云就可以感受和ACK一致的使用体验。您也可以查阅[Sealer Get-Started](https://github.com/alibaba/sealer/blob/main/docs/design)来获得更全面的集群使用方法。

### 快速创建ACK Distro集群
在创建集群之前，请根据[部署要求](requirements_zh.md)来检查您的环境是否满足ACK Distro的部署要求。

获取最新版sealer：

```bash
wget -c https://sealer.oss-cn-beijing.aliyuncs.com/sealers/sealer-v0.8.5-linux-amd64.tar.gz && \
      tar -xvf sealer-v0.8.5-linux-amd64.tar.gz -C /usr/bin
```

使用sealer获取ACK Distro制品，并创建集群：

```bash
sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1-20-4-ack-3 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password
```

查看集群状态：

```bash
kubectl get cs
```

### 【进阶】使用生产级别的配置创建Distro集群

ACK Distro有丰富的生产级别集群管理经验，我们目前提供了以下生产级别的功能：

1. 管理K8s管控组件的分区，自动地对K8s管控组件进行隔离和容量管理，以提升etcd性能以及OS稳定性
2. 集群预检工具，可以在集群部署之前检查出可能影响集群稳定性的隐患
3. 集群健康检查工具，可以一键检查集群是否健康
4. etcd周期备份工具，默认每天凌晨2点进行etcd备份
5. 集群审计日志，仅记录写操作，对于3m+3w集群，可以用1GiB空间记录约72h的集群写操作

#### 1) 管理K8s管控组件的分区

如果想让ACK Distro更好地管理它使用的磁盘，请按需准备好裸的数据盘（无需分区及挂载）：

- EtcdDevice: 分配给etcd的磁盘，容量必须大于20GiB，IOPS>3300，仅Master节点需要
- StorageDevice: 分配给docker和kubelet的磁盘，容量建议大于100GiB

准备好磁盘后，配置您的ClusterFile.yaml文件

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
# 使用sealer apply进行高阶部署
sealer apply -f ClusterFile.yaml
```

#### 2) 使用集群预检工具

```bash
# 部署集群时，默认会运行集群预检工具，如果出现了预检错误ErrorX，但您评估觉得可以忽略该报错，请按如下操作
sealer apply -f ClusterFile.yaml --env IgnoreErrors="ErrorX[;ErrorY]"

# 如果想忽略所有
sealer apply -f ClusterFile.yaml --env IgnoreErrors=all
```

#### 3) 使用集群健康检查工具

集群部署完成后，会默认触发一次健康检查，检查不通过会直接报错；之后，健康检查会周期性运行。

```bash
#您可以查询上一次周期运行的健康检查结果
trident health-check

#您也可以触发一次全新的健康检查
trident health-check --trigger-all

#更多功能
trident health-check --help
```

### 运维ACK Distro集群
扩容节点：

```bash
sealer join -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...]
```

缩容节点：

```bash
sealer delete -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...]
```

### 清理ACK Distro集群

```bash
sealer delete -a
```

## 使用方法
### Kubernetes使用方法
请参考Alibaba帮助中心、Kubernetes社区获取标准Kubernetes的使用方法：

- [https://help.aliyun.com/document_detail/309552.html](https://help.aliyun.com/document_detail/309552.html)
- [https://kubernetes.io/#](https://kubernetes.io/#)

### 网络插件的使用方法：
[Hybridnet 使用手册](https://github.com/alibaba/hybridnet/wiki)

### 存储插件的使用方法：
[Open-Local 本地存储插件用户手册](https://github.com/alibaba/open-local/blob/main/docs/user-guide/user-guide_zh_CN.md)

### 使用ACK纳管ACK-Distro集群：
[https://help.aliyun.com/document_detail/121053.html](https://help.aliyun.com/document_detail/121053.html)
