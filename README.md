# Home

Alibaba ACK Distro is a Kubernetes distribution based on Alibaba Container Service for Kubernetes to support production ready Kubernetes deployment for heterogeneous IaaS environment. Users can get complete content and community support for free through Alibaba Cloud. Its components have been verified and security checked by Alibaba Cloud Container Service for Kubernetes (ACK) and Alibaba Group's core business scenarios in large-scale production environment, with industry-leading security and reliability.

As a complete Kubernetes distribution, ACK Distro can be delivered to on-premise environment simply and quickly through [sealer](https://github.com/alibaba/sealer), an open-source application packaging delivery tool of Alibaba, helping users to manage their clusters more simply and flexibly. The components support both x86 and ARM hardware architectures, and include a high-performance network plugin [hybridnet](https://github.com/alibaba/hybridnet), which ensures that ACK Distro can run smoothly over a diverse infrastructure. At the same time, ACK Distro can be registered on the ACK service to achieve consistent resource management, policy compliance and traffic control, so that users can obtain the same user experience as the online ACK cluster.

## The difference between ACK Distro and ACK

The main difference between ACK Distro and ACK clusters is that ACK clusters are deployed on and managed by Alibaba Cloud, while ACK Distro clusters are managed by yourself and can be deployed on on-premise environments, other cloud service providers or even your own PCs.

ACK Distro, as a downstream of ACK, will keep up-to-date with ACK's release. ACK Distro will release the same version within one month after ACK releases a new version, and ACK keeps updating the minor version of Kubernetes once every six months in principle. Please refer to the [Appendix](docs/FAQ.md) for the specific release strategy.

## Features

### Cluster installation

- Support multiple deployment topologies including single-node, three-node, etcd/apiserver separation (under planning)
- Support preflight and post-check for cluster
- Support deployment on various IaaS such as ECS, VMware, VirtualBox, ZStack, OpenStack and bare metal
- Support deployment on various OS such as Red Hat, Debian, Open Anolis, Kylin, Windows (under planning)
- Support deployment on various architectures such as x86, arm64 (under planning), etc.

### Cluster operation and maintenance

- Support node scale, node replacement
- Support for being managed by CNStack Community Edition (under planning)
- Support cluster health check during runtime  (under planning)
- Support for backup/restore (under planning), Kubernetes version upgrade (under planning)

### High performance network

- Providing both overlay and underlay networking for containers in one or more clusters. Overlay and underlay containers can run on the same node and have cluster-  wide bidirectional network connectivity
- Flexible IP/Subnet management policies
- Intuitive and comprehensive statistics of network resources
- Multi-cluster networking

### Cloud-native local storage management system

- Support local storage pool management, dynamic volume provisioning, volume expansion and volume snapshot
- Support extended scheduler, Raw block volume
- Support volume metrics, IO Throttling

## Quick start

```bash
ARCH=amd64 # or arm64
wget https://ack-a-aecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/bin/${ARCH}/sealer-latest-linux-${ARCH}.tar.gz -O sealer-latest-linux-${ARCH}.tar.gz && \
      tar -xvf sealer-latest-linux-${ARCH}.tar.gz -C /usr/bin

sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1-20-4-ack-5 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password

kubectl get cs
```

For more information, please refer to: [User-guide](https://github.com/tamerga/ackdistro/tree/main/docs).

## Component Introduction

### Basic Components
Including:Apiserver/scheduler/controller-manager/kubelet/kube-proxy/coredns/metrics-server/kubectl/kubeadm, etc.

### Container during runtime
Including docker, containerd, nvidia-docker, etc.

### Cluster Installation Tools
[sealer](https://github.com/alibaba/sealer), open source

### Network plugin
[hybridnet](https://github.com/alibaba/hybridnet)，support underlay and overlay, open source

### Local storage plugin
[open-local](https://github.com/alibaba/open-local), Support local disk scheduling,open source

## Community
Please refer to: [community](docs/community.md)

## Communication Channels

- [DingTalk:](https://h5.dingtalk.com/circle/healthCheckin.html?dtaction=os&corpId=dingc6fc0a2fc2f6079fcc358aa147c3dfd3&eaa3ff=6eb60f&cbdbhh=qwertyuiop)

<!-- markdownlint-disable -->
<div align="">
  <img src="https://ack-a-aecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/6e13f507-51d0-48be-80e4-1929331f88ac.jpg" width="300" title="dingtalk">
</div>
<!-- markdownlint-restore -->

## License
ACK Distro is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for the full license text.
