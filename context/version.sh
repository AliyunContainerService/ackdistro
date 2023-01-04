#!/usr/bin/env bash
set -x

#kube_install_version=$(echo "${kube_install_version:-"v1.19.8"}" | grep "v" || kube_install_version="v${kube_install_version}")
#export kube_install_version=${kube_install_version}

export libseccomp_version=${libseccomp_version:-"2.5.4"}

export gperf_version=${gperf_version:-"3.1"}

export conntrack_version=${conntrack_version:-"1.4.4"}

#export containerd_version=${containerd_version:-"1.6.12"}

export seautil_version=${seautil_version:-"0.9.0"}
