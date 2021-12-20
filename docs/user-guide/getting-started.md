# Getting started

With the following Sealer directive, you can quickly build an ACK Distro cluster in an offline environment and experience the same user experience as ACK without reaching the public cloud. You can also check out  [Sealer Get-Started](https://github.com/alibaba/sealer/blob/main/docs/user-guide/get-started.md) for a more comprehensive guide on how to use the cluster.

## Create cluster
Get the latest version of sealer：
```bash
wget "https://acs-ecp.oss-cn-hangzhou.aliyuncs.com/tmp/sealer" -O /usr/bin/sealer && chmod +x /usr/bin/sealer 
```
Use sealer to get ACK Distro artifacts and create clusters:
```bash
sealer run registry.cn-hangzhou.aliyuncs.com/oecp/ack-distro:v1.20.4-aliyun.1-alpha5 -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...] -p password
```
View cluster status:
```bash
kubectl get cs
```

## Operation and maintenance cluster
Expansion node:
```bash
sealer join -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...]
```
Capacity reduction node：
```bash
sealer delete -m ${master_ip1}[,${master_ip2},${master_ip3}] [ -n ${worker_ip1}...]
```

## Cleanup cluster
```bash
sealer delete -a
```

## Instruction
Please refer to Alibaba Help Center and Kubernetes community for the usage of standard Kubernetes:
- [https://help.aliyun.com/document_detail/309552.html](https://help.aliyun.com/document_detail/309552.html)
- [https://kubernetes.io/#](https://kubernetes.io/#)

### ACK Distro’s recommendation on how to use the network plug-in:
[Hybridnet user manual](https://github.com/alibaba/hybridnet/wiki)

### ACK-Distro’s recommendation on how to use the storage plug-in:
[Open-local local storage plug-in user manul](https://github.com/alibaba/open-local/blob/main/docs/user-guide/user-guide_zh_CN.md)

### Use ACK to manage ACK-Distro cluster:
[https://help.aliyun.com/document_detail/121053.html](https://help.aliyun.com/document_detail/121053.html)
