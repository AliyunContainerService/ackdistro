#!/bin/bash

set -x

# remove the containers and images
docker ps -aq | xargs -I '{}' docker stop {}
docker ps -aq | xargs -I '{}' docker rm {}
docker image ls -aq | xargs -I '{}' docker image rm {}

# stop docker and remove the docker configure files
systemctl stop docker.service && systemctl disable docker.service
ip link delete docker0 type bridge || true
rm -rf /lib/systemd/system/docker.service
rm -rf /etc/systemd/system/docker.service
rm -rf /usr/lib/systemd/system/docker.service
rm -rf /etc/docker
systemctl daemon-reload

# kill dockerd process and related processes
for pid in $(ps aux | awk '{ if ($11 == "dockerd" || $11 == "containerd" || $11 == "containerd-shim") print $2 }')
do
  kill -9 ${pid}
done
for pid in $(ps aux | awk '{ if (match($11, ".*/dockerd$$") || match($11, ".*/containerd$$") || match($11, ".*/containerd-shim$$")) print $2 }')
do
  kill -9 ${pid}
done

# remove the sock files
rm -f /var/run/docker.sock
rm -f /var/run/dockershim.sock

# umount and clean the docker related directories
rm -rf /var/lib/docker/*

rm -f /usr/bin/conntrack
rm -f /usr/bin/containerd
rm -f /usr/bin/containerd-shim
rm -f /usr/bin/containerd-shim-runc-v2
rm -f /usr/bin/crictl
rm -f /usr/bin/ctr
rm -f /usr/bin/docker
rm -f /usr/bin/docker-init
rm -f /usr/bin/docker-proxy
rm -f /usr/bin/dockerd
rm -f /usr/bin/rootlesskit
rm -f /usr/bin/rootlesskit-docker-proxy
rm -f /usr/bin/runc
rm -f /usr/bin/vpnkit
rm -f /usr/bin/containerd-rootless-setuptool.sh
rm -f /usr/bin/containerd-rootless.sh
rm -f /usr/bin/nerdctl