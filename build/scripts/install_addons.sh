#!/usr/bin/env bash

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -x

# copy generate adp license script
cp "${scripts_path}/../etc/generate-adp-license.sh" /usr/bin/ || true
chmod +x /usr/bin/generate-adp-license.sh || true

# Apply yamls
if [ "$SkipCorednsConfigmap" != "true" ];then
  sed "s/##DNSDomain##/${DNSDomain}/g" ack-distro-yamls/coredns-cm.yaml | sed "s/##REGISTRY_IP##/${RegistryIP}/g" | sed "s/##REGISTRY_DOMAIN##/${RegistryDomain}/g" | kubectl apply -f -
fi
kubectl apply -f ack-distro-yamls/apiserver-lb-svc.yaml
kubectl apply -f ack-distro-yamls/clusters.open-cluster-management.io_managedclusters.crd.yaml

# Prepare helm config
prepare_helm_config

# wait 120s for apiserver ready
wait_for_apiserver || exit 1

# install kube core addons
helm_install kube-core || panic "failed to install kube-core"
kubectl create ns acs-system || true
kubectl create ns cluster-local || true

# create etcd secret
create_etcd_secret || exit 1

# install net plugin
if [ "$Network" == "calico" ];then
  helm_install calico || panic "failed to install calico"
else
  helm_install hybridnet || panic "failed to install hybridnet"
fi

# install required addons
helm_install l-zero || panic "failed to install l-zero"
if [ "${DefaultStorageClass}" == "yoda-lvm-default" ];then
  helm_install open-local || panic "failed to install open-local"
fi
helm_install csi-hostpath || panic "failed to install csi-hostpath"
helm_install etcd-backup || panic "failed to install etcd-backup"

echo "sleep 15 for l-zero crds ready"
sleep 15
helm_install l-zero-library || panic "failed to install l-zero-library"

# install optional addons
install_optional_addons ${Addons}

# set default storageclass and snapshot
kubectl annotate storageclass ${DefaultStorageClass} snapshot.storage.kubernetes.io/is-default-class="true" --overwrite
kubectl annotate storageclass ${DefaultStorageClass} storageclass.kubernetes.io/is-default-class="true" --overwrite

if [ "$Network" == "hybridnet" ];then
  create_subnet "${HostIPFamily}" "$PodCIDR" "init" || exit 1
fi

