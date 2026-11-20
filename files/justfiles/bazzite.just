# Rebase to Bazzite once you upgrade your GPU
upgrade-to-bazzite:
    #!/usr/bin/env bash
    set -euo pipefail

    gpu="$(lspci | grep -iE 'vga|3d|display' || true)"
    echo "detected gpu:"
    echo "${gpu}"
    echo

    if echo "${gpu}" | grep -qiE 'gtx 6[0-9]{2}|gtx 7[678][0-9]|gtx titan|gt 6[0-9]{2}|gt 7[1234]0|gk1[0-9]{2}|gk2[0-9]{2}'; then
        echo "heads up: it looks like you're still on a kepler gpu (like a gtx 660 ti)."
        echo "bazzite does not support nvidia 470xx — swap the gpu first or you'll fall back to nouveau."
        read -rp "continue anyway? [y/N] " kepler_ok
        [[ "${kepler_ok,,}" == "y" ]] || exit 0
        echo
    fi

    echo "pick your new gpu:"
    echo "  1) nvidia gtx 900 / 1000 series (e.g. gtx 1060)  -> bazzite-nvidia"
    echo "  2) nvidia gtx 16xx / rtx 2000+                   -> bazzite-nvidia-open"
    echo "  3) amd / intel                                   -> bazzite"
    read -rp "choice [1-3]: " gpu_choice

    case "${gpu_choice}" in
        1) suffix="-nvidia" ;;
        2) suffix="-nvidia-open" ;;
        3) suffix="" ;;
        *) echo "invalid choice" >&2; exit 1 ;;
    esac

    echo
    echo "pick desktop:"
    echo "  1) kde plasma (default)"
    echo "  2) gnome"
    read -rp "choice [1-2]: " de_choice

    case "${de_choice}" in
        1) de="" ;;
        2) de="-gnome" ;;
        *) echo "invalid choice" >&2; exit 1 ;;
    esac

    image="bazzite${de}${suffix}"
    ref="ghcr.io/ublue-os/${image}:stable"

    echo
    echo "about to rebase to: ${ref}"
    read -rp "proceed? [y/N] " confirm
    [[ "${confirm,,}" == "y" ]] || exit 0

    if command -v rpm-ostree >/dev/null 2>&1; then
        rpm-ostree rebase "ostree-unverified-registry:${ref}"
    else
        sudo bootc switch "${ref}"
    fi

    echo
    echo "done! reboot to boot into bazzite."
    echo "after rebooting, switch to the signed image with:"
    echo "  rpm-ostree rebase ostree-image-signed:docker://${ref}"
