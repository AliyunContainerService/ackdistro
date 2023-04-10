#!/usr/bin/env bash

set -x -e

assert_empty() {
  if [ "$2" == "" ]; then
    echo "$1 must be set, please check"
    exit 1
  fi
}

uninstall_docker() {
  bash uninstall-docker.sh
}

install_nerdctl() {
  cp -f $DIR_WORKSPACE/bin/nerdctl /usr/bin/nerdctl
  chmod +x /usr/bin/nerdctl
}

upgrade_config() {
  if ! grep "container-runtime=remote" kubeadm-flags.env; then
    cp /var/lib/kubelet/kubeadm-flags.env $DIR_BACKUP/
    sed -i 's#KUBELET_KUBEADM_ARGS=\"#KUBELET_KUBEADM_ARGS=\"--container-runtime=remote --container-runtime-endpoint=/run/containerd/containerd.sock #g' /var/lib/kubelet/kubeadm-flags.env
  fi
}

upgrade_containerd() {
  bash containerd.sh

  # master
  if [ "$1" = "master" ]; then
    bash init-registry.sh ${LocalRegistryPort} $DIR_WORKSPACE/registry ${LocalRegistryDomain}
  fi
}

upgrade_main() {
  if [ "${LocalRegistryPort}" == "" ];then
    echo "Env LocalRegistryPort must be set, please check"
    exit 1
  fi
  if [ "${LocalRegistryDomain}" == "" ];then
    echo "Env LocalRegistryDomain must be set, please check"
    exit 1
  fi
  systemctl stop kubelet
  uninstall_docker
  install_nerdctl
  upgrade_config
  upgrade_containerd $ROLE
  systemctl start kubelet
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
    --dir-workspace)
      DIR_WORKSPACE=$2
      shift
      ;;
    --dir-backup)
      DIR_BACKUP=$2
      shift
      ;;
    esac
    shift
  done

  assert_empty ROLE ${ROLE}
  assert_empty DIR_WORKSPACE ${DIR_WORKSPACE}
  assert_empty DIR_BACKUP ${DIR_BACKUP}

  ######################################################
  upgrade_main
}

main "$@"
