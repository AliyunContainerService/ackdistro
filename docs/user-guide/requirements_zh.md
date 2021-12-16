# 部署要求
为了顺利构建ACK Distro，您需要确保达到以下配置要求。

## 术语说明
- Master节点：Kubernetes集群控制节点，负责管理整个集群，包含集群元数据库（etcd），一般为3节点高可用模式，也支持单节点部署
- Master0节点：配置文件中的第1台Master节点
- Worker节点：Kubernetes集群的工作节点，负责运行应用，数量可从0~N

## 系统要求
### os：
- CentOS 7.5/7.6/7.7/7.8/7.9/8.0
- RHEL 7.8
- Ubuntu 18.04
- Anolis 8.2
- 麒麟V10（Kylin V10）

### Architecture：
- amd64/x86_64
- arm64

### Kernel：
- 4.18.*
- 4.19.*
- 3.10.*

### IaaS：
- 物理机
- 阿里云
- 华为云
- 电信云
- 易捷行云 EasyStack
- VMWare
- ZStack

### Linux系统配置：
| **配置项** | **部署时是否会自动配置** |
| --- | --- |
| 所有节点的root用户权限（ssh密码或密钥） | 否 |
| 所有节点需配置ntpd或chronyd连接到同一时钟源 | 否 |
| 所有节点的Hostname彼此之间不能重复 | 否 |
| 关闭SELinux | 是 |
| 停用firewalld服务 | 是 |
| 开启iptables forward功能 | 是 |
| 关闭swap | 是 |

## 网络要求
### 端口开放
集群内请放通所有端口访问。

### 容器网络要求 
overlay 模式：

- 每个节点需要开放 8472 udp 端口、11021 tcp 端口
- 节点网络（IaaS 平台）需要放行节点 8472 udp 端口

underlay 网络：

- 客户规划至少一个 C的IP
- 如果每个节点只有一张网卡，网卡的上联交换机端口需要配置 trunk
- Kubernetes 使用的机器需要在同一个二层容器网络 vlan 内
- 每个节点需要开放 11021 tcp 端口

## 最小资源要求
|  | **Master** | **Worker** |
| --- | --- | --- |
| **CPU** |  2core | 1core |
| **Memory** | 4GiB | 2GiB |

