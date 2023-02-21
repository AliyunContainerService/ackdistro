# ACK Distro
## 简介
Alibaba ACK Distro（即ACK发行版）是阿里巴巴针对异构Iaas环境发布的Kubernetes发行版，使用者可通过阿里云ACR免费获取完整内容并获得社区支持。其核心组件经过阿里云ACK服务和阿里巴巴集团核心业务场景的大规模生产环境验证和安全检查，具备业界领先的安全性与可靠性。

ACK Distro作为完整的Kubernetes发行版，通过阿里巴巴开源的应用打包交付工具[Sealer](https://github.com/alibaba/sealer)，可以简单、快速地交付到离线环境，帮助使用者更简单、敏捷地管理自己的集群。核心组件同时支持X86和ARM硬件架构，所包含的高性能网络插件[Hybridnet](https://github.com/alibaba/hybridnet)，可以确保ACK Distro能够丝滑运行于多样化的基础设施之上。同时，ACK Distro可以被注册到阿里云ACK服务上，实现资源管理、策略合规、流量管控一致，让使用者获得和线上ACK集群一致的用户体验。

## ACK Distro和ACK的区别
ACK Distro和线上ACK集群的主要区别在于，线上ACK集群部署在阿里云弹性计算服务器上，并且由阿里云ACK服务进行管理，而ACK Distro的集群则由用户自己管理，可以部署在离线环境、其他云服务商甚至自己的PC上。
​
ACK Distro作为ACK的下游，会紧跟ACK的发版节奏，具体发版策略请参阅[FAQ](docs/FAQ_zh.md)。

## 产品优势
**安全可靠**：核心组件来自阿里云ACK服务，并保持同步更新。这些核心组件经历了数十万商业用户和阿里集团核心业务场景的严苛生产验证，安全性与可靠性经过实践检验，达到业界领先水平。

**敏捷易用**：ACK Distro深度结合阿里开源的集群应用打包交付工具Sealer，分钟级实现集群的自动化部署、扩缩容、升级等集群生命周期管理功能。

**一致体验**：ACK Distro集群可以被公有云ACK平滑地管理，实现资源管理一致、策略合规一致、流量管控一致、应用部署一致；同时，公有云ACK所支持的应用解决方案也能无差别的部署在ACK Distro集群内。

**多样兼容**：核心组件同时支特X86和ARM硬件架构，同时ACK Distro包含的高性能网络插件Hybridnet，又使得网络环境的多样性成为可能，最终确保ACK Distro能够丝滑运行于多样化的基础设施之上

## 核心功能
### 集群创建

- 支持单节点非高可用、三节点高可用、etcd/apiserver分离（规划中）多种部署形态
- 支持环境预检和部署完成后的集群验证；（规划中）
- 支持在ECS、VMware、VirtualBox、ZStack、OpenStack、裸金属等多种IaaS上部署；
- 支持在Redhat系、Debian系、Open Anolis、Kylin、Windows（规划中）等多种OS上部署；
- 支持在x86、arm64（规划中）等多种架构上部署。

### 集群运维

- 支持节点扩缩容、节点替换
- 支持被CNStack社区版纳管（规划中）
- 支持运行时集群健康检查（规划中）
- 支持备份/恢复（规划中）、Kubernetes版本升级（规划中）

### 高性能网络

- 支持underlay 和 overlay 容器混合部署，兼具 “通过隧道网络与底层网络环境部署完全解耦”   和“通过非隧道高性能网络与底层网络灵活对接” 两大优势；
- 灵活的IP管理策略、自由的网段动态扩缩容以及丰富的 IP 指定特性
- 直观、全面的网络资源审计
- 多集群网络能力支持

### 本地存储管理

- 支持本地存储池管理、存储卷动态分配、存储卷扩容、存储卷快照
- 支持存储调度算法扩展
- 支持存储卷监控

## 快速开始

```bash
ARCH=amd64 # or arm64
wget http://ack-a-aecp.oss-cn-hangzhou.aliyuncs.com/ack-distro/sealer/sealer-0.9.2-beta2-linux-${ARCH}.tar.gz -O sealer-latest-linux-${ARCH}.tar.gz && \
      tar -xvf sealer-latest-linux-${ARCH}.tar.gz -C /usr/bin

sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1-22-15-ack-4 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password

kubectl get cs
```

更多内容请见：[user-guide](docs/user-guide)

## 组件介绍
### 基础组件
包括apiserver/scheduler/kcm/kubelet/kube-proxy/coredns/metrics-server/kubectl/kubeadm等
### 容器运行时
包括docker、containerd、nvidia-docker等组件
### 集群安装工具
即[sealer](https://github.com/alibaba/sealer?spm=5176.25695502.J_6725771560.1.67f754edVGlgxa)，已开源
### 网络插件
即[hybridnet](https://github.com/alibaba/hybridnet?spm=5176.25695502.J_6725771560.2.67f754edVGlgxa)，支持underlay与overlay。项目已开源
### 本地存储插件
即[open-local](https://github.com/alibaba/open-local?spm=5176.25695502.J_6725771560.3.67f754edVGlgxa)，支持本地磁盘调度。项目已开源

## 社区
请见：[community](docs/community_zh.md)

## 联系我们

客户支持钉钉群

![image](https://user-images.githubusercontent.com/8002217/219262258-f3ced02a-c361-4191-b55b-99e932dfbc6e.png)


## License
ACK Distro is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for the full license text.
