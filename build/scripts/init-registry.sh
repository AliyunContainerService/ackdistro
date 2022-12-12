#!/bin/bash
# Copyright © 2021 Alibaba Group Holding Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -e
set -x
scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

# prepare registry storage as directory
cd $(dirname "$0")

REGISTRY_PORT=${1-5000}
VOLUME=${2-/var/lib/registry}
REGISTRY_DOMAIN=${3-sea.hub}

CONTAINER_RUNTIME=docker
if ! utils_command_exists docker;then
  if containerd --version; then
    CONTAINER_RUNTIME=containerd
  else
    echo "either docker and containerd not found, please check"
    exit 1
  fi
fi

container=sealer-registry
rootfs=$(dirname "$(pwd)")
config="$rootfs/etc/registry_config.yml"
htpasswd="$rootfs/etc/registry_htpasswd"
certs_dir="$rootfs/certs"
image_dir="$rootfs/images"

mkdir -p "$VOLUME" || true

runtimeRun() {
  if [ "$CONTAINER_RUNTIME" == "containerd" ];then
    nerdctl container run $@
  else
    docker run $@
  fi
}

runtimeStart() {
  if [ "$CONTAINER_RUNTIME" == "containerd" ];then
    nerdctl start $@
  else
    docker start $@
  fi
}

runtimeInspect() {
  if [ "$CONTAINER_RUNTIME" == "containerd" ];then
    nerdctl container inspect $@
  else
    docker inspect $@
  fi
}

runtimeGetContainerStatus() {
  if [ "$CONTAINER_RUNTIME" == "containerd" ];then
    nerdctl container inspect $@ | grep '"Status"' | awk '{print $2}' | tr -d ','
  else
    docker inspect --format '{{json .State.Status}}' $@
  fi
}

startRegistry() {
  n=1
  while (( n <= 3 ));do
    echo "attempt to start registry"
    runtimeStart $container && break
    (( n++ ))
    sleep 3
  done
}

load_images() {
  for image in "$image_dir"/*;do
    if [ ! -f "${image}" ];then
      continue
    fi
    if [ "$CONTAINER_RUNTIME" == "containerd" ];then
      ctr image import "${image}"
    else
      docker load -q -i "${image}"
    fi
  done
}

check_registry() {
  n=1
  while (( n <= 3 ));do
    registry_status=$(runtimeGetContainerStatus sealer-registry)
    [[ "$registry_status" == \"running\" ]] && break
    (( n++ ))
    sleep 3
  done
  if [[ "$registry_status" != \"running\" ]]; then
    echo "sealer-registry is not running, status: $registry_status"
    return 1
  fi
}

load_images

## rm container if exist.
if [ "$CONTAINER_RUNTIME" == "containerd" ];then
  runtimeInspect $container &>/dev/null && nerdctl rm -f $container
else
  docker inspect $container &>/dev/null && docker rm -f $container
fi

regArgs="-d --restart=always \
--net=host \
--name $container \
-v $certs_dir:/certs \
-v $VOLUME:/var/lib/registry \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/$REGISTRY_DOMAIN.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/$REGISTRY_DOMAIN.key"

if [ -f $config ]; then
    sed -i "s/5000/$1/g" $config
    regArgs="$regArgs \
    -v $config:/etc/docker/registry/config.yml"
fi

if [ -f $htpasswd ]; then
  runtimeRun $regArgs \
    -v $htpasswd:/htpasswd \
    -e REGISTRY_AUTH=htpasswd \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/htpasswd \
    -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" registry:2.7.1 || startRegistry
else
  runtimeRun $regArgs registry:2.7.1 || startRegistry
fi

if ! check_registry;then
  exit 1
fi

sleep 5
