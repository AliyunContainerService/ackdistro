#!/bin/bash

# remove the containers and images
docker ps -aq | xargs -I '{}' docker stop {}
docker ps -aq | xargs -I '{}' docker rm {}
docker image ls -aq | xargs -I '{}' docker image rm {}

# stop docker and remove the docker configure files
systemctl stop docker.service && systemctl disable docker.service
rm -f /lib/systemd/system/docker.service
rm -f /etc/systemd/system/docker.service
rm -f /usr/lib/systemd/system/docker.service
rm -f /etc/docker/daemon.json

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

ip link delete docker0 type bridge || true

# remove the docker and related binaries
yum remove -y docker docker-engine docker-ce docker-ee containerd.io docker-ce-cli container-selinux
rm -f $(which -a docker)
rm -f $(which -a dockerd)
rm -f $(which -a docker-init)
rm -f $(which -a docker-proxy)
rm -f $(which -a containerd)
rm -f $(which -a containerd-shim)
rm -f $(which -a runc)
rm -f $(which -a ctr)
rm -f $(which -a crictl)

# umount and clean the docker related directories
rm -rf /var/lib/docker/*
if [[ $? != 0 ]]; then
  exit 1
fi