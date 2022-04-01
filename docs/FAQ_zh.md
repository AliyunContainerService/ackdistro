# FAQ
## ACK-distro发版策略
ACK Distro发版策略如下：

- 发布周期：ACK Distro会不定期推出更新版本。版本更新一般在：
  1. 公有云ACK发布新Kubernetes版本后的2个月内，ACK Distro支持同版本的Kubernetes.
  2. ACK Distro自身的功能更新以及各种漏洞修复时，会推出相应的更新版本。
- 技术支持：ACK Distro提供最近一个Kubernetes版本的创建功能，以及最近三个Kubernetes大版本的技术支持。对于过期版本的Kubernetes集群，ACK Distro将停止支持。

版本号定义：
v{major}.{minio}.{patch}-ackdistro-k8s{kubernetes version}
例如：

- v1.0.0-ackdistro-k8s1.20.4
- v1.0.1-ackdistro-k8s1.20.4
- v1.1.0-ackdistro-k8s1.22.4

更多的公有云ACK Kubernetes版本策略，请参考[ACK 用户文档](https://help.aliyun.com/document_detail/115453.html)
