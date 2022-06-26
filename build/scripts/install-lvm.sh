#! /bin/bash

scripts_path=$(
  cd $(dirname $0)
  pwd
)
source "${scripts_path}"/utils.sh

set -x

if vgcreate --version; then
  exit 0
fi

utils_os_env

if [ "$OSRelease" == "" ]; then
  utils_error "install lvm now only support redhat like OS"
  exit 1
fi

tar -xvf ${scripts_path}/../tgz/lvm-${OSRelease}.tgz -C ${scripts_path}/../rpm/

dir=${scripts_path}/../rpm/lvm-${OSRelease}
if ! output=$(rpm -ivh --force --nodeps $(ls ${dir}/${app}/*.rpm) 2>&1); then
  utils_error "failed to install rpm, output:${output}, maybe your rpm db was broken, please see https://cloudlinux.zendesk.com/hc/en-us/articles/115004075294-Fix-rpmdb-Thread-died-in-Berkeley-DB-library for help"
  exit 1
fi