### Overview
This chart contains two components, node-problem-detector(npd) and evener. node-problem-detector aims to make various node problems visible to the upstream layers in cluster management stack. It is a daemon which runs on each node, detects node problems and reports them to apiserver.

npd can detect a lot of errors:

- Basic daemon problem: ntp service is down
- Hardware problems: cpu, memory, disk failure
- Kernel issues: kernel deadlock, file system crash
- Container runtime problem: runtime is not responding
- ...

On the ACK, we have done some enhancements to the functionality and deployment of the  Community npd, mainly in:

1. More error detection:
- FD check: check the usage of the native file handle, when more than 80% will report the event
- Public network check: check if the node can access the public network
- NTP check: check if the node has time offset
- RAM role check: check if the node has RAM role

2. Integrated archiving and alerting:
- Support event archive to SLS (Alibaba Cloud Log Service)
- Support event send alarm to DingDing


If you want to know more about this version of npd, you can refer to https://github.com/AliyunContainerService/node-problem-detector. npd could classifies the monitored issues and converts them into different Conditions and Events. At the same time,eventer can capture the events in the cluster, we can set the level of the event we want to monitor in the chart.Currently, the notification methods we support are dingtalk and sls. We can use the above two way to respond more quickly to problems in the cluster.

### Verify
On your workstation, run `kubectl get events -w`. On the node, run `sudo sh -c "echo 'kernel: BUG: unable to handle kernel NULL pointer dereference at TESTING' >> /dev/kmsg"`. Then you should see the `KernelOops` event. Run again  `kubectl get events -w`. if you see the  `KernelOops` . Successful installation.

### configuration
The following table lists the configurable parammeters of the cronhpa ahd their default values.

| Parameter                                | Description                                                  | Default                                                    |
| ---------------------------------------- | ------------------------------------------------------------ | ---------------------------------------------------------- |
| npd.image.repository                     | The remote address of the npd image.                         | registry.cn-beijing.aliyuncs.com/acs/node-problem-detector |
| npd.image.tag                            | The tag of the npd image.                                    | v0.6.3-16-g30dab97                                         |
| alibaba_cloud_plugins                    | Select the plugin to install                                 | fd_check                                                   |
| eventer.image.repository                 | The remote address of the eventer image.                     | registry.cn-hangzhou.aliyuncs.com/acs/eventer              |
| eventer.image.tag                        | The tag of the image                                         | v1.6.0-4c4c66c-aliyun                                      |
| eventer.image.pullPolicy                 | image pull strategy                                          | IfNotPresent                                               |
| eventer.sinks.sls.enabled                | Whether sls is turned on monitoring                          | false                                                      |
| eventer.sinks.sls.project                | sls's project name                                           | ""                                                         |
| eventer.sinks.sls.logstore               | sls's logstore name                                          | ""                                                         |
| eventer.sinks.dingtalk.enabled           | Whether dingtalk is turned on monitoring                     | false                                                      |
| eventer.sinks.dingtalk.level             | Alarm level                                                  | warning                                                    |
| eventer.sinks.dingtalk.label             | This refers to the cluster_id                                | ""                                                         |
| eventer.sinks.dingtalk.token             | dingtalk's access_token                                      | ""                                                         |
| eventer.sinks.dingtalk.monitorkinds      | Kind type of dingtalk monitoring，You can monitor multiple events of different kind types at the same time. e.g.,Pod or Node | ""                                                         |
| eventer.sinks.dingtalk.monitornamespaces | Dingtalk monitored namespace，You can monitor multiple namespaces simultaneously. empty means all namespaces | ""                                                         |
| eventer.sinks.eventbridge.enabled        | Whether event bridge is turned on monitoring                 | false                                                           |