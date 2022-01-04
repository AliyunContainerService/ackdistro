# Deployment Requirements

To successfully install ACK Distro, you need to ensure that the following requirements are met.

## Terminology Description

- Master: Kubernetes cluster control node, which is responsible for managing the whole cluster, including cluster metadata database (etcd), which is generally a 3-node high availability mode and also supports single-node deployment.
- Master0: The first Master node in the configuration file.
- Worker: the working node of Kubernetes cluster, which is responsible for running applications, and the number can range from 0~N

## System requirements
### os：

- CentOS 7.5/7.6/7.7/7.8/7.9/8.0
- RHEL 7.8
- Ubuntu 18.04
- Anolis 8.2
- Kylin V10

### Architecture：

- amd64/x86_64
- arm64

### Kernel：

- 4.18.*
- 4.19.*
- 3.10.*

### IaaS：

- Bare mental
- Alicloud
- Hicloud
- Telecom Cloud
- EasyStack
- VMWare
- ZStack

### Linux System Configuration:

| **Configuration items** | **Will it be automatically configured during deployment?** |
| --- | --- |
| Root user rights of all nodes (ssh password or key)  | No |
| All nodes need to be configured with ntpd or chronyd connected to the same clock source | No |
| Hostname of all nodes cannot be duplicated with each other | No |
| Shut down SELinux | Yes |
| Disable the firewalld service | Yes |
| Enable the iptables forward function | Yes |
| Shut down swap | Yes |

## Network requirements

### Ports open

Please access all ports in the cluster.

### Container network requirements

Overlay mode:

- Each node needs to open 8472 udp port and 11021 tcp port.
- Node network (IaaS platform) needs to release the node 8472 udp port.

Underlay network:

- Customers plan at least one C IP
- If there is only one NIC per node, the NIC's uplink switch port needs to be configured with trunk
- Machines used by Kubernetes need to be in the same Layer 2 container network vlan
- Each node needs to have the 11021 tcp port open

## Resource requirements
|  | **Master** | **Worker** |
| --- | --- | --- |
| **CPU** |  2core | 1core |
| **Memory** | 4GiB | 2GiB |



