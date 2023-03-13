#!/bin/bash
# this file can't import utils.sh, cause it will be put into /usr/bin for kubelet.service

version_ge() {
  test "$(echo "$@" | tr ' ' '\n' | sort -rV | head -n 1)" == "$1"
}

disable_selinux() {
  if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
  fi
  if ! getenforce | grep Disabled;then
    setenforce 0 || true
  fi
}

set_modules() {
  if [ ! -d /etc/modprobe.d/ ]; then
    echo "we can't find dir /etc/sysconfig/modules/, so linux mod can't be reloaded after reboot, please check"
    exit 1
  fi

  # put modprobe configuration into ackdistro.modules
  modfile=/etc/modprobe.d/ackdistro.modules
  cat <<EOF >${modfile}
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- br_netfilter
modprobe -- xt_set
modprobe -- ip_tables
modprobe -- ip6_tables
EOF

  kernel_version=$(uname -r | cut -d- -f1)
  if version_ge "${kernel_version}" 4.19; then
    echo "modprobe -- nf_conntrack" >>${modfile}
  else
    echo "modprobe -- nf_conntrack_ipv4" >>${modfile}
  fi

  chmod 755 /etc/modprobe.d/ackdistro.modules
  /etc/modprobe.d/ackdistro.modules
}

set_sysctl() {
  cat <<EOF >/etc/sysctl.d/k8s.conf
# set by ack-distro
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.conf.all.arp_filter = 0
net.ipv4.conf.all.rp_filter = 0
fs.may_detach_mounts = 1
EOF

  while read -r line;do
    if ! grep "${line}" /etc/sysctl.conf;then
      echo "${line}" >> /etc/sysctl.conf
    fi
  done < /etc/sysctl.d/k8s.conf

  sysctl --system
}

swapoff -a || true
[[ -f /etc/fstab ]] && sed -i '/\sswap\s/d' /etc/fstab
iptables -P FORWARD ACCEPT
disable_selinux
set_modules
set_sysctl