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


STORAGE=${1:-/var/lib/docker}
REGISTRY_DOMAIN=${2-sea.hub}
REGISTRY_PORT=${3-5000}
CONTAINER_RUNTIME=${4-docker}

# Install container runtime
if [ "$CONTAINER_RUNTIME" == "containerd" ];then
  chmod a+x containerd.sh
  bash containerd.sh || exit 1
else
  chmod a+x docker.sh
  bash docker.sh || exit 1
fi

chmod a+x init-kube.sh

bash init-kube.sh || exit 1