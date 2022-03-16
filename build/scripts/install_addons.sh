#!/usr/bin/env bash

Network=$1
Addons=$2

# net plugin
if [ "$Network" == "calico" ];then
  helm -n kube-system upgrade -i calico charts/calico
else
  helm -n kube-system upgrade -i hybridnet charts/hybridnet
fi

# must be installed addons
helm -n kube-system upgrade -i open-local charts/open-local
helm -n kube-system upgrade -i l-zero charts/l-zero
helm -n acs-system upgrade -i l-zero-library charts/l-zero-library

# optional addons
IFS=,
for addon in ${Addons};do
  helm -n acs-system upgrade -i ${addon} charts/${addon}
done