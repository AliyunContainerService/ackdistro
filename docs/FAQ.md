# FAQ

## ACK-distro publishing strategy
Based on the [ACK release strategy](https://help.aliyun.com/document_detail/115453.html), the ACK Distro release strategy is as follows:

- Release cycle: In principle, ACK keeps the frequency of updating the big version of Kubernetes once every six months. After the big version is released, ACK will release the update of the small version from time to time due to the function update and bug fix.
- Cluster creation: ACK Distro only publishes the big version of Kubernetes even number, and supports the creation of two big versions of Kubernetes, such as v1.16 and v1.18. When the new version of Kubernetes is released, the older version will no longer open the creation function. For example, when v1.20 is released, v1.16 will no longer open the creation function.
- Upgrade and O&M guarantee: Ensure the stable operation of the three most recent major versions of Kubernetes, and support the upgrade function of the latest version to the previous two major versions. For example, if the current latest version is v1.20, ACK Distro supports the upgrade function of v1.18 and v1.16. It is recommended that you upgrade your Kubernetes version in a timely manner as there is a risk of instability and cluster upgrade failure for outdated versions.
- Technical support: ACK Distro provides technical support for the last three major Kubernetes releases in the community, but ACK Distro will stop supporting Kubernetes clusters with outdated versions.



Version number definition:
v{kubernetes-major}.{kubernetes-minio}.{kubernetes-patch}-ack-{patch}
For example:

- v1.20.4-ack-1
- v1.20.4-ack-2
- v1.22.8-ack-1
