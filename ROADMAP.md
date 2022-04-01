# Roadmap

## 2021-12
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

## 2022-03
- Support sealer clusterfile v2
- Preflight and health-check
- Support etcd backup
- Cluster Auditing
- Support kubernetes version 1.22 and support automatically release a new CloudImage version
- Support deployment on ARM64
- Automatic E2E test 

## 2022-06
- Using OpenKruise to support advanced workload management
- K8s diagnose, which can automatically diagnose k8s problems
- Support large cluster(500 nodes, 20000 pods) and K8s Risk Control for large cluster
- Improve unattended capability on various OS and IaaS
- Support etcd/apiserver separation (under planning)
- IPv4&IPv6 Dual Stack
- Support more arch, runtime and IaaS

## 2022-09
- Using OpenYurt to support edge node management
- Node pool, which can scale nodes horizontally
- Cloud Native LoadBanlancer
- Support  xLarge cluster(1000 nodes, 30000 pods)
- Support upgrade k8s version
- Turbo full link performance by 40%

## Future versions
- Advanced scheduler for CPU, GPU(shared) and Gang scheduling. 
- Sandboxed Container and Trusted Execution Environment
- Hyper Converged Infrastructure
- Support deployment on Windows