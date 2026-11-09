#!/bin/sh
# Fresh-install test (minutes; skips the AUR packages that compile): full `chezmoi apply`, scripts included, as a new
# sudo user in a throwaway CachyOS container. Can't cover the KDE session, the SDDM login screen or
# the profile picture (no systemd/dbus); use test/vm.sh for those.
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
exec podman run --rm -v "$repo:/dotfiles:ro" docker.io/cachyos/cachyos:latest sh -euc '
# the CachyOS desktop ISO already ships these and the dotfiles rely on them
# (cachyos-fish-config brings fish, fisher and bat; kconfig brings kwriteconfig6)
pacman -Syu --noconfirm --needed base-devel git sudo chezmoi cachyos-fish-config kconfig
useradd -m -s /usr/bin/fish tester
echo "tester ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/tester
su - tester -s /bin/sh -c "
set -eu
CHEZMOI_SKIP_COMPILED=1 chezmoi --source /dotfiles apply
list=\$HOME/.local/state/chezmoi-missing-packages
if [ -s \"\$list\" ]; then echo FAIL: packages did not install:; cat \"\$list\"; exit 1; fi
# files on disk must match the repo after the scripts ran
chezmoi --source /dotfiles verify --exclude scripts
bat --list-themes --color=never | grep -qx kanagawa-wave || { echo FAIL: bat theme missing; exit 1; }
test -f ~/.config/fish/themes/kanagawa-wave.theme || { echo FAIL: fisher did not install the fish theme; exit 1; }
ls -d ~/.themes/Layan* >/dev/null || { echo FAIL: Layan GTK theme missing; exit 1; }
echo ok
"
'
