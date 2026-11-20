#!/usr/bin/env bash
set -oue pipefail

KVER="$(basename "$(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d | head -n 1)")"
if [[ -z "${KVER}" ]]; then
  echo "could not find kernel in /usr/lib/modules" >&2
  exit 1
fi

if [[ ! -d "/usr/src/kernels/${KVER}" ]]; then
  if ! dnf5 install -y "kernel-devel-${KVER}"; then
    dnf5 install -y fedora-repos-archive
    dnf5 install -y --enablerepo=updates-archive "kernel-devel-${KVER}"
    dnf5 remove -y fedora-repos-archive
  fi
fi

akmods --force --kernels "${KVER}" --kmod nvidia-470xx

if ! find "/usr/lib/modules/${KVER}" -name "nvidia*.ko*" | grep -q .; then
  echo "nvidia-470xx failed to build for ${KVER}" >&2
  cat /var/cache/akmods/nvidia-470xx/*.log 2>/dev/null || true
  exit 1
fi

depmod -a "${KVER}"
