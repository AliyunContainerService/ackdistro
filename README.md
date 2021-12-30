# Home

Alibaba ACK Distro (ACK distribution) is the Kubernetes distribution released by Alibaba for heterogeneous Iaas environment. Users can get complete content and long-term support for free through Alicloud ACR. Its core components have been verified and security checked by Alicloud ACK service and Alibaba Group's core business scenarios in large-scale production environment, with industry-leading security and reliability.
​

As a complete Kubernetes distribution, ACK Distro can be delivered to offline environment simply and quickly through Sealer, an open source application packaging delivery tool of Alibaba, helping users to manage their clusters more simply and flexibly. The core components support both X86 and ARM hardware architectures, and include a high-performance network plug-in Hybridnet, which ensures that ACK Distro can run smoothly over a diverse infrastructure. At the same time, ACK Distro can be registered on the Alicloud ACK service to achieve consistent resource management, policy compliance and traffic control, so that users can obtain the same user experience as the online ACK cluster.

## The difference between ACK Distro and ACK
The main difference between ACK Distro and online ACK clusters is that online ACK clusters are deployed on AliCloud Elastic Compute servers and managed by AliCloud ACK service, while ACK Distro's clusters are managed by users themselves and can be deployed on offline environments, other cloud service providers or even their own PCs.
​

ACK Distro, as a downstream of ACK, will keep up with ACK's release. ACK Distro will release the same version within one month after ACK releases a new version, and ACK keeps updating the major version of Kubernetes once every six months in principle. Please refer to the Appendix for the specific release strategy.

## Core function

#### Cluster creation
- Support multiple deployment configurations including single-node non-highly available, three-node highly available, etcd/apiserver separation (under planning).
- Support environment pre-testing and cluster verification after deployment; (under planning).
- Support deployment on various IaaS such as ECS, VMware, VirtualBox, ZStack, OpenStack and bare metal;
- Support deployment on multiple OS such as Redhat, Debian, Open Anolis, Kylin, Windows (under planning);
- Support deployment on various architectures such as x86, arm64 (under planning), etc.

#### Cluster operation and maintenance
- Support node expansion and contraction, node replacement
- Support for being managed by CNStack Community Edition (under planning)
- Support cluster health check during runtime  (under planning)
- Support for backup/restore (under planning), Kubernetes version upgrade (under planning)

#### High performance network
- Support mixed deployment of underlay and overlay containers, with the advantages of "complete decoupling from the underlying network environment through tunneled networks" and "flexible interfacing with the underlying network through non-tunneled high-performance networks"
- Flexible IP management policies, free segment dynamic expansion and contraction, and rich IP designation features
- An intuitive and comprehensive audit of network resources
- Multi-cluster network capacity support

#### Local Storage Management
- Support local storage pool management, dynamic volume provisioning, storage volume expansion and volume snapshot
- Support for extended scheduler
- Support for volume metrics

## Qucik start
```bash
wget -c http://sealer.oss-cn-beijing.aliyuncs.com/sealers/sealer-v0.5.2-linux-amd64.tar.gz && \\
        tar -xvf sealer-v0.5.2-linux-amd64.tar.gz -C /usr/bin

sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1.20.4-aliyun.1-alpha6 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password

kubectl get cs
```
For more information, please refer to: [User-guide].

## Component Introduction

#### Basic Components
Including:Inapiserver/scheduler/kcm/kubelet/kube-proxy/coredns/metrics-server/kubectl/kubeadm, etc.

#### Container during runtime
Including docker, containerd, nvidia-docker, etc.

#### Cluster Installation Tools
[sealer] (https://github.com/alibaba/sealer?spm=5176.25695502.J_6725771560.1.67f754edVGlgxa), open source

#### Network plugin
[hybridnet] (https://github.com/alibaba/hybridnet?spm=5176.25695502.J_6725771560.2.67f754edVGlgxa)，support underlay and overlay, open source

#### Local storage plugin
[open-local] (https://github.com/alibaba/open-local?spm=5176.25695502.J_6725771560.3.67f754edVGlgxa), Support local disk scheduling,open source

## Community
Please refer to: [community] (docs/community.md)

## License
ACK Distro is licensed under the Apache License, Version 2.0. See [LICENSE] (LICENSE) for the full license text.
