#!/usr/bin/env bash

set -x -e

assert_empty() {
  if [ "$2" == "" ]; then
    echo "$1 must be set, please check"
    exit 1
  fi
}

upgrade_log() {
  echo $(date +"[%Y%m%d %H:%M:%S]: ") $1
}

upgrade_kubernetescni() {
  rpm -ivh --force --nodeps $DIR_KUBE/rpm/$(ls $DIR_KUBE/rpm | grep kubernetes-cni)
  upgrade_log "kubernetes-cni is already updated to 0.8.0."
}

upgrade_kubeadm() {
  /usr/bin/cp -f $DIR_KUBE/bin/kubeadm /usr/bin/
  chmod +x /usr/bin/kubeadm
  upgrade_log "kubeadm is already updated to ${VERSION_NUM}."
}

upgrade_kubeadm_config() {
  /usr/bin/cp -f $DIR_KUBE/kubeadm.yaml $DIR_KUBE/kubeadm-master0.yaml
  /usr/bin/cp -f /etc/kubernetes/kubeadm.yaml $DIR_KUBE/kubeadm-join.yaml
  if [ "$1" = "0" ]; then
    sed -i '264,277d' $DIR_KUBE/kubeadm-master0.yaml
    sed -i '20,117d' $DIR_KUBE/kubeadm-join.yaml
    cat $DIR_KUBE/kubeadm-master0.yaml $DIR_KUBE/kubeadm-join.yaml > $DIR_KUBE/kubeadm.yaml
  fi
  sed -i "/advertiseAddress/d" $DIR_KUBE/kubeadm.yaml
  sed -i "s#kubeadm.k8s.io/v1beta2#kubeadm.k8s.io/v1beta3#g" $DIR_KUBE/kubeadm.yaml
  sed -i "s#kubeadm.k8s.io/v1beta1#kubeadm.k8s.io/v1beta3#g" $DIR_KUBE/kubeadm.yaml
  if ! grep "kubernetesVersion: ${TARGET_VERSION}" $DIR_KUBE/kubeadm.yaml; then
    sed -i "/kubernetesVersion:/ s/${CURRENT_VERSION}/${TARGET_VERSION}/" $DIR_KUBE/kubeadm.yaml
  fi
  if ! grep "admissionregistration.k8s.io/v1beta1=true" $DIR_KUBE/kubeadm.yaml; then
    sed -i "/runtime-config/ s/$/,admissionregistration.k8s.io\/v1beta1=true/" $DIR_KUBE/kubeadm.yaml
  fi
  if ! grep "tls-cipher-suites" $DIR_KUBE/kubeadm.yaml; then
    sed -i "/enable-aggregator-routing/a\ \ \ \ tls-cipher-suites: TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384" $DIR_KUBE/kubeadm.yaml
  fi
}

upgrade_kube_controller() {
  sed -i "s#--port=10252#--port=0#g" /etc/kubernetes/manifests/kube-controller-manager.yaml
}

upgrade_nodes() {
  if [ "$1" = "master" ]; then
    upgrade_kubeadm_config $2
    if ! curl -k https://localhost:6443/version 2>&1 | grep gitVersion | grep $VERSION_NUM; then
      kubeadm upgrade apply $TARGET_VERSION --config=$DIR_KUBE/kubeadm.yaml --experimental-patches=$DIR_KUBE/patch_files --force --ignore-preflight-errors=CoreDNSUnsupportedPlugins,CoreDNSMigration --certificate-renewal=false
    else
      upgrade_log "Control Plane has been upgraded to [$VERSION_NUM], skip."
    fi
    upgrade_kube_controller
  fi

  if [ "$1" = "worker" ]; then
    kubeadm upgrade node
  fi

  upgrade_log "Successful upgrade to [$VERSION_NUM]. $(hostname)"
}

upgrade_kubectl() {
  /usr/bin/cp -f $DIR_KUBE/bin/kubectl /usr/bin/
  chmod +x /usr/bin/kubectl
  upgrade_log "kubectl is already updated to ${VERSION_NUM}."
}

upgrade_kubelet() {
  /usr/bin/cp -f $DIR_KUBE/bin/kubelet /usr/bin/
  chmod +x /usr/bin/kubelet
  upgrade_log "kubelet is already updated to ${VERSION_NUM}."

  systemctl daemon-reload
  systemctl enable kubelet
  systemctl restart kubelet
}

upgrade_summary() {
  if [ "$1" = "master" ]; then
    echo ">>>>>> master change summary begin >>>>>>>>" | tee $DIR_BACKUP/upgrade-change.log
    diff $DIR_KUBE/kubeadm.yaml $DIR_KUBE/kubeadm.yaml | tee -a $DIR_BACKUP/upgrade-change.log
    diff $DIR_BACKUP/kubernetes/manifests /etc/kubernetes/manifests | tee -a $DIR_BACKUP/upgrade-change.log
    diff $DIR_BACKUP/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf | tee -a $DIR_BACKUP/upgrade-change.log
    echo ">>>>>> master change summary end >>>>>>>>" | tee -a $DIR_BACKUP/upgrade-change.log
  else
    echo ">>>>>> worker change summary begin >>>>>>>>" | tee $DIR_BACKUP/upgrade-change.log
    diff $DIR_BACKUP/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf | tee -a $DIR_BACKUP/upgrade-change.log
    echo ">>>>>> worker change summary end >>>>>>>>" | tee -a $DIR_BACKUP/upgrade-change.log
  fi
}

upgrade_main() {
  upgrade_kubernetescni
  upgrade_kubeadm
  upgrade_nodes $ROLE $ON_MASTER0
  upgrade_kubectl
  upgrade_kubelet
  upgrade_summary $ROLE
}

main() {
  while
    [[ $# -gt 0 ]]
  do
    key="$1"

    case $key in
    --role)
      ROLE=$2
      shift
      ;;
    --cv)
      CURRENT_VERSION=$2
      shift
      ;;
    --tv)
      TARGET_VERSION=$2
      shift
      ;;
    --dir-kube)
      DIR_KUBE=$2
      shift
      ;;
    --dir-backup)
      DIR_BACKUP=$2
      shift
      ;;
    --on-master0)
      ON_MASTER0=$2
      shift
      ;;
    esac
    shift
  done

  assert_empty ROLE ${ROLE}
  assert_empty CURRENT_VERSION ${CURRENT_VERSION}
  assert_empty TARGET_VERSION ${TARGET_VERSION}
  assert_empty DIR_KUBE ${DIR_KUBE}
  assert_empty DIR_BACKUP ${DIR_BACKUP}

  VERSION_NUM=$(echo $TARGET_VERSION | sed 's/v//' | sed 's/-aliyun.1//g')

  ######################################################
  upgrade_main
}

main "$@"
