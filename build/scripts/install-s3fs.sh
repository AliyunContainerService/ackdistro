#! /bin/bash

scripts_path=$(
  cd $(dirname $0)
  pwd
)
source "${scripts_path}"/utils.sh

set -x

if s3fs --version; then
  exit 0
fi

utils_os_env

if [ "$OSRelease" == "" ]; then
  echo "install s3fs now only support Redhat-like OS, skip install it"
  exit 0
fi

tar -xvf ${scripts_path}/../tgz/s3fs-${OSRelease}.tgz -C ${scripts_path}/../rpm/

dir=${scripts_path}/../rpm/s3fs-${OSRelease}
if ! output=$(rpm -ivh --force --nodeps $(ls ${dir}/*.rpm) 2>&1); then
  panic "failed to install rpm, output:${output}, maybe your rpm db was broken, please see https://cloudlinux.zendesk.com/hc/en-us/articles/115004075294-Fix-rpmdb-Thread-died-in-Berkeley-DB-library for help"
fi