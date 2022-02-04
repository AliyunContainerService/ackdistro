# Release Note

## v1.20.4-ack-2
Features:
- Support multiple deployment topologys including single-node, three-node
- Support deployment on various IaaS such as ECS, VMware, VirtualBox, ZStack, OpenStack and bare metal
- Support deployment on various OS such as Redhat, Debian, Open Anolis, Kylin
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

sealer run ack-agility-registry.cn-shanghai.cr.aliyuncs.com/ecp_builder/ackdistro:v1.20.4-ack-2 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password

kubectl get cs
```