#!/usr/bin/env bash
set -o errexit

die() {
  msg="$*"
  echo "[Error] ${msg}" >&2
  exit 1
}

checkEnvExist() {
  for i in "$@"; do
    if [ -z "${!i}" ]; then
      die "Please set environment ${i}"
    fi
  done
}

checkEnvExist libseccomp_version gperf_version seautil_version conntrack_version

cri=docker
if
  [ -z "${cri}" ] || [ "${cri}" != "docker" ] && [ "${cri}" != "containerd" ]
then
  die "Usage '${0} docker' or '${0} containerd'"
fi

if [ "${cri}" = "containerd" ] && ! checkEnvExist containerd_version; then
  die "Please set environment 'containerd_version'"
fi

gperf_url="https://ftp.gnu.org/gnu/gperf"
gperf_tarball="gperf-${gperf_version:-}.tar.gz"
gperf_tarball_url="${gperf_url}/${gperf_tarball}"

libseccomp_url="https://github.com/seccomp/libseccomp"
libseccomp_tarball="libsecdownload cri with dockercomp-${libseccomp_version:-}.tar.gz"
libseccomp_tarball_url="${libseccomp_url}/releases/download/v${libseccomp_version}/${libseccomp_tarball}"

seautil_url="https://github.com/sealerio/sealer"
seautil_tarball_amd64="seautil-v${seautil_version:-}-linux-amd64.tar.gz"
seautil_tarball_arm64="seautil-v${seautil_version}-linux-arm64.tar.gz"
seautil_tarball_amd64_url="${seautil_url}/releases/download/v${seautil_version}/${seautil_tarball_amd64}"
seautil_tarball_arm64_url="${seautil_url}/releases/download/v${seautil_version}/${seautil_tarball_arm64}"

install_url="https://sealer.oss-cn-beijing.aliyuncs.com/auto-build"

##https://github.com/osemp/moby/releases/download/v19.03.14/docker-amd64.tar.gz
##registry ${ARCH} image: ghcr.io/osemp/distribution-amd64/distribution:latest
if [ "${cri}" = "docker" ]
then
  docker_version="19.03.15"
  #docker_url="https://github.com/osemp/moby"
  docker_url="https://github.com/moby/moby"
  cri_tarball_amd64="docker-amd64.tar.gz"
  cri_tarball_arm64="docker-arm64.tar.gz"
  cri_tarball_amd64_url="${docker_url}/releases/download/v${docker_version}/${cri_tarball_amd64}"
  cri_tarball_arm64_url="${docker_url}/releases/download/v${docker_version}/${cri_tarball_arm64}"
  registry_tarball_amd64="docker-amd64-registry-image.tar.gz"
  registry_tarball_arm64="docker-arm64-registry-image.tar.gz"
  echo "download docker version ${docker_version}"
fi

registry_tarball_amd64_url="${install_url}/${registry_tarball_amd64}"
registry_tarball_arm64_url="${install_url}/${registry_tarball_arm64}"
echo "download registry tarball ${registry_tarball_amd64_url}"

mkdir -p {arm,amd}64/{cri,bin,images}

##https://www.netfilter.org/pub/conntrack-tools/conntrack-tools-1.4.4.tar.bz2
wget "${install_url}/linux-amd64/conntrack-${conntrack_version:-}/bin/conntrack" && mv conntrack "amd64/bin"
wget "${install_url}/linux-arm64/conntrack-${conntrack_version}/bin/conntrack" && mv conntrack "arm64/bin"

echo "download gperf version ${gperf_version}"
mkdir -p "rootfs/lib"
curl -sLO "${gperf_tarball_url}" && mv "${gperf_tarball}" "rootfs/lib"

echo "download libseccomp version ${libseccomp_version}"
curl -sLO "${libseccomp_tarball_url}" && mv "${libseccomp_tarball}" "rootfs/lib"

echo "download seautil version ${seautil_version}"
wget -q "${seautil_tarball_amd64_url}" && tar zxvf "${seautil_tarball_amd64}" -C "amd64/bin"
wget -q "${seautil_tarball_arm64_url}" && tar zxvf "${seautil_tarball_arm64}" -C "arm64/bin"

echo "download cri with ${cri}"
wget -q "${cri_tarball_amd64_url}" && mv "${cri_tarball_amd64}" "amd64/cri/docker.tar.gz"
wget -q "${cri_tarball_arm64_url}" && mv "${cri_tarball_arm64}" "arm64/cri/docker.tar.gz"

echo "download distribution image ${registry_tarball_amd64}"
wget -q "${registry_tarball_amd64_url}" && mv "${registry_tarball_amd64}" "amd64/images/registry.tar"
wget -q "${registry_tarball_arm64_url}" && mv "${registry_tarball_arm64}" "arm64/images/registry.tar"
