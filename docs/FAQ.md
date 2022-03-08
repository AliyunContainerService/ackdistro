# FAQ

## ACK-distro release strategy

ACK Distro release strategy is as follows:

- Release cycle: ACK Distro will release updated versions from time to time. The version update is generally: 
  1. Within 2 months after the public cloud ACK releases the new Kubernetes version, ACK Distro supports the same version of Kubernetes. 
  2. When ACK Distro's own function updates and various bug fixes, the corresponding updated version will be released.
- Technical support: ACK Distro provides installation of the latest Kubernetes version and technical support for the last three major Kubernetes releases in the community, but will stop supporting Kubernetes clusters with outdated versions.

Version number definition:
v{kubernetes-major}.{kubernetes-minio}.{kubernetes-patch}-ack-{patch}
For example:

- v1.20.4-ack-1
- v1.20.4-ack-2
- v1.22.8-ack-1

Please refer to [ACK user doc](https://help.aliyun.com/document_detail/115453.html) for ACK version strategy
