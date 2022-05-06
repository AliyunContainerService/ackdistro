# 开始

## 安装方法
通过以下Sealer指令，您可以快速地在离线环境搭建一套ACK Distro集群，无需到达公有云就可以感受和ACK一致的使用体验。您也可以查阅[Sealer Get-Started](https://github.com/alibaba/sealer/blob/main/docs/design)来获得更全面的集群使用方法。

### 创建ACK Distro集群
在创建集群之前，请根据[部署要求](requirements_zh.md)来检查您的环境是否满足ACK Distro的部署要求。

获取最新版sealer：

```bash
wget -c https://sealer.oss-cn-beijing.aliyuncs.com/sealers/sealer-v0.8.5-linux-amd64.tar.gz && \
      tar -xvf sealer-v0.8.5-linux-amd64.tar.gz -C /usr/bin
```

使用sealer获取ACK Distro制品，并创建集群：

```bash
sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1.20.4-ack-3 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password
```

查看集群状态：

```bash
kubectl get cs
```

#### 【进阶】使用生产级别的配置进行集群创建
ACK Distro有丰富的生产级别集群管理经验，我们目前提供了以下生产级别的功能：
1. 管理K8s管控组件的分区，自动地对K8s管控组件进行隔离和容量管理，以提升etcd性能以及OS稳定性
2. 集群预检工具，可以在集群部署之前检查出可能影响集群稳定性的隐患
3. 集群健康检查工具，可以一键检查集群是否健康
4. etcd周期备份工具，默认每天凌晨2点进行etcd备份
5. 集群审计日志，仅记录写操作，对于3m+3w集群，可以用1GiB空间记录约72h的集群写操作



如果想让ACK Distro帮助您进行磁盘分区管理，请按需准备好裸的数据盘（无需分区及挂载）：
- EtcdDevice: 分配给etcd的磁盘，容量必须大于20GiB，IOPS>3300，仅Master节点需要
- StorageDevice: 分配给docker和kubelet的磁盘，容量建议大于100GiB
  准备好磁盘后，


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
