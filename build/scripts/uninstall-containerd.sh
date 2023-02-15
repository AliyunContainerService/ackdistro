#!/bin/bash

# remove containers and images
crictl ps -aq | xargs crictl stop
crictl ps -aq | xargs crictl rm
crictl images -q | xargs crictl rmi

# stop containerd and remove the containerd configure files
systemctl stop containerd.service && systemctl disable containerd.service
rm -f /lib/systemd/system/containerd.service
rm -f /etc/systemd/system/containerd.service
rm -f /usr/lib/systemd/system/containerd.service
rm -f /etc/containerd/config.toml
rm -f /etc/cni/net.d

# kill containerd process and related processes
for pid in $(ps aux | awk '{ if ($11 == "containerd" || $11 == "containerd-shim" || $11 == "containerd-shim-runc-v1" || $11 == "containerd-shim-runc-v2") print $2 }')
do
  kill -9 ${pid}
done
for pid in $(ps aux | awk '{ if (match($11, ".*/containerd$$") || match($11, ".*/containerd-shim$$") || match($11, ".*/containerd-shim-runc-v1$$") || match($11, ".*/containerd-shim-runc-v2$$")) print $2 }')
do
  kill -9 ${pid}
done

# remove sock file
rm -f /var/run/containerd/containerd.sock

# remove containerd and related binaries
rm -f $(which -a containerd)
rm -f $(which -a containerd-shim)
rm -f $(which -a containerd-shim-runc-v1)
rm -f $(which -a containerd-shim-runc-v2)
rm -f $(which -a runc)
rm -f $(which -a ctr)
rm -f $(which -a crictl)
rm -r $(which -a nerdctl)

# umount and clean containerd related directories
rm -rf /var/lib/containerd/*
if [[ $? != 0 ]]; then
  exit 1
fi

rm -rf /var/lib/nerdctl/*
if [[ $? != 0 ]]; then
  exit 1
fi