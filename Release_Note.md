# Release Note

## v1-20-4-ack-5
Features:

- [Installation] Support install cluster on ipv6-only, ipv6-dual-stack hosts
- [Installation] Support configure DNSDomain/ServiceNodePortRange for k8s
- [Installation] Use lvm, Logical Volume Manager, to manage partition of docker and kubelet
- [CNI] Upgrade hybridnet from v0.4.2 to v0.6.0, which support ipv6 dual stack, introduce GlobalBGP type Network etc. [CHANGELOG](https://github.com/alibaba/hybridnet/blob/main/CHANGELOG.md)
- [CSI] Upgrade open-local v0.5.4 to v0.5.5. [CHANGELOG](https://github.com/alibaba/open-local/releases)
- [CRI] Support nvidia-docker, which will be automatically installed when GPU driver has been detected
- [CRI] Support configure LimitNOFILE for docker.service
- [Addon] Add local dns cache and paralb
- [Test] Add E2E auto test

Usage:

```bash
ARCH=amd64 # or arm64
wget -c https://ack-a-aecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/bin/${ARCH}/sealer-latest-linux-${ARCH}.tar.gz && \
      tar -xvf sealer-latest-linux-${ARCH}.tar.gz -C /usr/bin

sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1-20-4-ack-5 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password

kubectl get cs
trident health-check
```

## v1-20-4-ack-3
Features:

- Upgrade sealer to [v0.8](https://github.com/sealerio/sealer/releases/tag/v0.8.0), which provides stronger cluster management capabilities and simpler API
- Upgrade open-local v0.2.3 to v0.5.4, which support raw block volume, io-throttling, ephemeral local volumes etc. [CHANGELOG](https://github.com/alibaba/open-local/releases)
- Upgrade hybridnet from v0.1.1 to v0.4.2, which support multicluster feature, BGP mode for an underlay network, introduce felix for NetworkPolicy etc. [CHANGELOG](https://github.com/alibaba/hybridnet/blob/main/CHANGELOG.md)
- Support automatically manage disk capacity for k8s daemons, to avoid affecting the stability of the OS
- Support etcd backup cronjob, which will run a backup every day at 02:00 by default
- Support cluster auditing, which only record WRITE request and can use only 1GiB storage to save audit logs for the last 72h on a 3m+3w cluster
- Support preflight tool, which can determine whether it can be successful before cluster deployment
- Support cluster health-check tool, which can check whether the cluster is healthy with one click
- Fix some bugs

Usage:

```bash
wget -c https://sealer.oss-cn-beijing.aliyuncs.com/sealers/sealer-v0.8.5-linux-amd64.tar.gz && \
      tar -xvf sealer-v0.8.5-linux-amd64.tar.gz -C /usr/bin

sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1-20-4-ack-3 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password

trident health-check
```

## v1-20-4-ack-2
Features:

- Support multiple deployment topologies including single-node, three-node
- Support deployment on various IaaS such as ECS, VMware, VirtualBox, ZStack, OpenStack and bare metal
- Support deployment on various OS such as Red Hat, Debian, Open Anolis, Kylin
- Support deployment on various architectures such as x86
- Support node scale, node replacement
- Support for being managed by CNStack Community Edition
- Providing both overlay and underlay networking for containers in one or more clusters. Overlay and underlay containers can run on the same node and have cluster-wide bidirectional network connectivity
- Flexible IP/Subnet management policies
- Intuitive and comprehensive statistics of network resources
- Multi-cluster networking
- Support local storage pool management, dynamic volume provisioning, volume expansion and volume snapshot
- Support extended scheduler, Raw block volume
- Support volume metrics, IO Throttling

Usage:

```bash
wget -c http://sealer.oss-cn-beijing.aliyuncs.com/sealers/sealer-v0.5.2-linux-amd64.tar.gz && \
        tar -xvf sealer-v0.5.2-linux-amd64.tar.gz -C /usr/bin

sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1-20-4-ack-2 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password

kubectl get cs
```