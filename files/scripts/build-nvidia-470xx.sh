#!/usr/bin/env bash
set -oue pipefail

KVER="$(basename "$(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d | head -n 1)")"
if [[ -z "${KVER}" ]]; then
  echo "could not find kernel in /usr/lib/modules" >&2
  exit 1
fi

FEDORA_VER="$(rpm -E %fedora)"

if [[ ! -d "/usr/src/kernels/${KVER}" ]]; then
  if ! dnf5 install -y "kernel-devel-${KVER}"; then
    dnf5 install -y fedora-repos-archive
    dnf5 install -y --enablerepo=updates-archive "kernel-devel-${KVER}"
    dnf5 remove -y fedora-repos-archive
  fi
fi

dnf5 install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

rm -rf /tmp/akmod-dl /tmp/akmod-src /tmp/kmod-out
mkdir -p /tmp/akmod-dl /tmp/akmod-src /tmp/kmod-out

dnf5 download --disablerepo='rpmfusion-free*,fedora-multimedia*' --destdir=/tmp/akmod-dl akmod-nvidia-470xx
dnf5 install -y --disablerepo='rpmfusion-free*,fedora-multimedia*' --setopt=install_weak_deps=False xorg-x11-drv-nvidia-470xx-kmodsrc

(
  cd /tmp/akmod-src
  rpm2cpio /tmp/akmod-dl/akmod-nvidia-470xx-*.rpm | cpio -idm
)

SRPM="$(find /tmp/akmod-src -name 'nvidia-470xx-kmod-*.src.rpm' | head -n 1)"
if [[ -z "${SRPM}" ]]; then
  echo "could not extract nvidia-470xx-kmod src.rpm" >&2
  exit 1
fi

chmod 1777 /tmp /var/tmp
chmod -R a+rX /tmp/akmod-src
chown -R akmods:akmods /tmp/kmod-out

if ! runuser -u akmods -- akmodsbuild --kernels "${KVER}" --outputdir /tmp/kmod-out --logfile /tmp/kmod-out/build.log "${SRPM}"; then
  echo "akmodsbuild failed for ${KVER}:" >&2
  cat /tmp/kmod-out/build.log >&2 || true
  exit 1
fi

mapfile -t KMOD_RPMS < <(find /tmp/kmod-out -maxdepth 1 -name 'kmod-nvidia-470xx-*.rpm' ! -name '*-debug*')
if (( ${#KMOD_RPMS[@]} == 0 )); then
  echo "no kmod-nvidia-470xx rpms produced" >&2
  ls -la /tmp/kmod-out >&2 || true
  exit 1
fi

dnf5 install -y --disablerepo='rpmfusion-free*,rpmfusion-nonfree*' mesa-libEGL.i686

dnf5 install -y --disablerepo='rpmfusion-free*,fedora-multimedia*' --setopt=install_weak_deps=False \
  "${KMOD_RPMS[@]}" \
  xorg-x11-drv-nvidia-470xx \
  xorg-x11-drv-nvidia-470xx-cuda \
  xorg-x11-drv-nvidia-470xx-libs \
  xorg-x11-drv-nvidia-470xx-libs.i686

rm -rf /tmp/akmod-dl /tmp/akmod-src /tmp/kmod-out
dnf5 remove -y xorg-x11-drv-nvidia-470xx-kmodsrc rpmfusion-free-release rpmfusion-nonfree-release
systemctl disable akmods.service || true

if ! find "/usr/lib/modules/${KVER}" -name "nvidia*.ko*" | grep -q .; then
  echo "nvidia-470xx kernel module missing in /usr/lib/modules/${KVER}" >&2
  exit 1
fi

depmod -a "${KVER}"
