#!/usr/bin/env bash

set -x -e

assert_empty() {
  if [ "$2" == "" ]; then
    echo "$1 must be set, please check"
    exit 1
  fi
}

rollback_log() {
  echo $(date +"[%Y%m%d %H:%M:%S]: ") $1
}

#downgrade_cni() {
#  rpm -ivh --force --nodeps $DIR_KUBE/rpm/$(ls $DIR_KUBE/rpm | grep cni)
#  rollback_log "downgrade kubernetes cni succeeded"
#}

downgrade_kubectl() {
  /usr/bin/cp -f $DIR_BACKUP/kubelet /usr/bin/
  chmod +x /usr/bin/kubectl
  rollback_log "downgrade kubectl succeeded"
}

downgrade_kubeadm() {
  /usr/bin/cp -f $DIR_BACKUP/kubeadm /usr/bin/
  chmod +x /usr/bin/kubeadm
  cp -f $DIR_BACKUP/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  rollback_log "rollback kubeadm succeeded"
}

downgrade_kubelet() {
  /usr/bin/cp -f $DIR_BACKUP/kubelet /usr/bin/
  cp -f $DIR_BACKUP/kubernetes/config.yaml /var/lib/kubelet/config.yaml
  chmod +x /usr/bin/kubelet

  systemctl daemon-reload
  systemctl enable kubelet
  systemctl restart kubelet

  sleep 10
  rollback_log "downgrade kubelet succeeded"
}

restore_config() {
  if [ "$ROLE" = "master" ]; then
    cp -f $DIR_BACKUP/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
    sleep 10
    cp -f $DIR_BACKUP/kubernetes/manifests/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml
    sleep 10
    cp -f $DIR_BACKUP/kubernetes/manifests/kube-scheduler.yaml /etc/kubernetes/manifests/kube-scheduler.yaml
    sleep 10
    rollback_log "restore manifests directory succeeded"
  fi
  #waitpodrunning
}

rollback_main() {
#  downgrade_cni
  downgrade_kubectl
  downgrade_kubeadm
  downgrade_kubelet
  restore_config $ROLE
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
    --dir-kube)
      DIR_KUBE=$2
      shift
      ;;
    --dir-backup)
      DIR_BACKUP=$2
      shift
      ;;
    *)
      upgrade_log "unknown option [$key]"
      exit 1
      ;;
    esac
    shift
  done

  assert_empty ROLE ${ROLE}
  assert_empty DIR_KUBE ${DIR_KUBE}
  assert_empty DIR_BACKUP ${DIR_BACKUP}

  ######################################################
  rollback_main
}

main "$@"
