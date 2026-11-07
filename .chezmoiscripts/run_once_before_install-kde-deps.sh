#!/bin/sh
# Packages the dotfiles expect but chezmoi doesn't store: themes, apps and dev tools.
# shortcut: Arch/CachyOS only (yay comes from the cachyos repo), add other package managers if a non-Arch machine shows up.
set -e
command -v pacman >/dev/null || { echo "pacman not found: install the packages below manually"; exit 0; }
# -Syu first: a fresh install still has the ISO's package databases, and yay won't sync them
sudo pacman -Syu --needed --noconfirm yay vimix-cursors
pkgs="kora-icon-theme wezterm-nightly-bin spotify zen-browser-bin
  kdeconnect proton-vpn-gtk-app protonmail-bridge proton-pass-bin proton-pass-cli-bin proton-mail-bin
  gitui git-delta github-cli cocogitto stylua lua51 luarocks otf-monaspace-nerdfonts ttf-firacode-nerd
  calibre mkvtoolnix-gui vlc qbittorrent localsend yacreader-poppler torbrowser-launcher spicetify-bin"
# AUR packages; --noconfirm skips PKGBUILD review. yay keeps going past failed builds;
# don't fail the script on them, or chezmoi aborts the apply before writing any dotfiles.
# shellcheck disable=SC2086
yay -S --needed --noconfirm $pkgs || true
# shellcheck disable=SC2086
missing=$(pacman -T $pkgs || true)
# reported at the very end of the apply by run_after_zz-report-missing-packages.sh
list="${XDG_STATE_HOME:-$HOME/.local/state}/chezmoi-missing-packages"
if [ -n "$missing" ]; then mkdir -p "$(dirname "$list")"; echo "$missing" > "$list"; fi
