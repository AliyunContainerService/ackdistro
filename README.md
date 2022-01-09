# Home

Alibaba ACK Distro (ACK distribution) is the Kubernetes distribution released by Alibaba for heterogeneous IaaS environment. Users can get complete content and long-term support for free through Alicloud ACR. Its components have been verified and security checked by Alicloud ACK service and Alibaba Group's core business scenarios in large-scale production environment, with industry-leading security and reliability.
​

As a complete Kubernetes distribution, ACK Distro can be delivered to offline environment simply and quickly through [sealer](https://github.com/alibaba/sealer), an open source application packaging delivery tool of Alibaba, helping users to manage their clusters more simply and flexibly. The components support both X86 and ARM hardware architectures, and include a high-performance network plugin [hybridnet](https://github.com/alibaba/hybridnet), which ensures that ACK Distro can run smoothly over a diverse infrastructure. At the same time, ACK Distro can be registered on the Alicloud ACK service to achieve consistent resource management, policy compliance and traffic control, so that users can obtain the same user experience as the online ACK cluster.

## The difference between ACK Distro and ACK
The main difference between ACK Distro and online ACK clusters is that online ACK clusters are deployed on AliCloud Elastic Compute servers and managed by AliCloud ACK service, while ACK Distro clusters are managed by yourself and can be deployed on offline environments, other cloud service providers or even your own PCs.
​

ACK Distro, as a downstream of ACK, will keep up with ACK's release. ACK Distro will release the same version within one month after ACK releases a new version, and ACK keeps updating the minor version of Kubernetes once every six months in principle. Please refer to the [Appendix](docs/FAQ.md) for the specific release strategy.

## Features

### Cluster installation

- Support multiple deployment topologys including single-node, three-node, etcd/apiserver separation (under planning)
- Support preflight and post-check for cluster
- Support deployment on various IaaS such as ECS, VMware, VirtualBox, ZStack, OpenStack and bare metal
- Support deployment on various OS such as Redhat, Debian, Open Anolis, Kylin, Windows (under planning)
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

## Qucik start

```bash
wget -c http://sealer.oss-cn-beijing.aliyuncs.com/sealers/sealer-v0.5.2-linux-amd64.tar.gz && \
        tar -xvf sealer-v0.5.2-linux-amd64.tar.gz -C /usr/bin

sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1.20.4-ack-2 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password

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

## License
ACK Distro is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for the full license text.
