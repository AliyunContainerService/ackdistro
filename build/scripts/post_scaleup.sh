#!/usr/bin/env bash

scripts_path=$(cd `dirname $0`; pwd)
source "${scripts_path}"/utils.sh

set -x

source "${scripts_path}"/default_values.sh

process_taints_labels "$RemoveMasterTaint" "$PlatformType" || exit 1

sleep 15
trident_process_reconcile "$ComponentToInstall" || exit 1