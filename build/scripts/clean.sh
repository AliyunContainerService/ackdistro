#!/bin/bash

scripts_path=$(cd `dirname $0`; pwd)

set -x

# remove container runtime
bash ${scripts_path}/docker-uninstall.sh || true
bash ${scripts_path}/containerd-uninstall.sh || true

# remove k8s
rm -f /usr/bin/kubelet-pre-start.sh
rm -f /usr/bin/kubeadm
rm -f /usr/bin/kubetcl
rm -f /usr/bin/kubelet

rm -f /etc/sysctl.d/k8s.conf
rm -f /etc/systemd/system/kubelet.service
rm -rf /etc/systemd/system/kubelet.service.d
rm -rf /var/lib/kubelet/
rm -f /var/lib/kubelet/config.yaml

# reload
systemctl daemon-reload