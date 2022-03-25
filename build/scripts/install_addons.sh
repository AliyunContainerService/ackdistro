#!/usr/bin/env bash

Network=$1
Addons=$2

# net plugin
if [ "$Network" == "calico" ];then
  helm -n kube-system upgrade -i calico chart/calico
else
  helm -n kube-system upgrade -i hybridnet chart/hybridnet
fi

# must be installed addons
helm -n kube-system upgrade -i l-zero chart/l-zero
helm -n kube-system upgrade -i open-local chart/open-local

echo "sleep 15 for l-zero crds ready"
sleep 15
helm -n acs-system upgrade -i l-zero-library chart/l-zero-library

# optional addons
#IFS=,
#for addon in ${Addons};do
#  helm -n acs-system upgrade -i ${addon} ../chart/${addon}
#done