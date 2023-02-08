#!/usr/bin/env bash
set -o errexit

unset PREFIX DESTDIR

arch=${ARCH:-$(uname -m)}
##workdir="$(mktemp -d build-libseccomp.XXXXX)"

libseccomp_version="2.5.1"
#libseccomp_url="https://github.com/seccomp/libseccomp"
libseccomp_tarball="libseccomp-${libseccomp_version}.tar.gz"
#libseccomp_tarball_url="${libseccomp_url}/releases/download/v${libseccomp_version}/${libseccomp_tarball}"
cflags="-O2"

gperf_version="3.1"
#gperf_url="https://ftp.gnu.org/gnu/gperf"
gperf_tarball="gperf-${gperf_version}.tar.gz"
#gperf_tarball_url="${gperf_url}/${gperf_tarball}"
#gperf_install_dir="/usr/local/gperf"

# We need to build the libseccomp library from sources to create a static library for the musl libc.
# However, ppc64le and s390x have no musl targets in Rust. Hence, we do not set cflags for the musl libc.
if [ "${arch}" != "ppc64le" ]; [ "${arch}" != "s390x" ]; then
  # Set FORTIFY_SOURCE=1 because the musl-libc does not have some functions about FORTIFY_SOURCE=2
  cflags="-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=1 -O2"
fi

die() {
  msg="$*"
  echo "[Error] ${msg}" >&2
  exit 1
}

build_and_install_gperf() {
  echo "Build and install gperf version ${gperf_version}"
  tar -xf "${gperf_tarball}"
  pushd "gperf-${gperf_version}"
  # Unset $CC for configure, we will always use native for gperf
  CC="" ./configure --prefix="/usr/local"
  make
  make install
  popd
  echo "Gperf installed successfully"
}

build_and_install_libseccomp() {
  echo "Build and install libseccomp version ${libseccomp_version}"
  tar -xf "${libseccomp_tarball}"
  pushd "libseccomp-${libseccomp_version}"
  ./configure --prefix="/usr/local" CFLAGS="${cflags}" --enable-static --host="${arch}"
  make
  make install
  popd
  echo "Libseccomp installed successfully"
}

# gperf is required for building the libseccomp.
build_and_install_gperf
build_and_install_libseccomp
