#!/bin/sh
# Packages the dotfiles expect but chezmoi doesn't store: themes, apps and dev tools.
# shortcut: Arch/CachyOS only (yay comes from the cachyos repo), add other package managers if a non-Arch machine shows up.
set -e
command -v pacman >/dev/null || { echo "pacman not found: install the packages below manually"; exit 0; }
# same as CachyOS Hello's "Rank mirrors": a fresh install's mirrorlist isn't sorted for this location
if command -v cachyos-rate-mirrors >/dev/null; then sudo cachyos-rate-mirrors || echo "mirror ranking failed; keeping the current mirrorlist"; fi
# -Syu first: a fresh install still has the ISO's package databases, and yay won't sync them
# cachyos-gaming-*: CachyOS Hello's "Install Gaming packages" (steam, lutris, heroic, proton, mangohud, ...)
# yay only when missing: an existing yay-bin/yay-git conflicts with the repo yay, and --noconfirm refuses to replace it
yay=; command -v yay >/dev/null || yay=yay
# shellcheck disable=SC2086 # empty $yay must vanish, not become an empty argument
sudo pacman -Syu --needed --noconfirm $yay vimix-cursors sddm cachyos-gaming-meta cachyos-gaming-applications
pkgs="kora-icon-theme wezterm-nightly-bin spotify zen-browser-bin
  kdeconnect proton-vpn-gtk-app protonmail-bridge proton-pass-bin proton-pass-cli-bin proton-mail-bin
  gitui git-delta github-cli cocogitto stylua lua51 luarocks otf-monaspace-nerdfonts ttf-firacode-nerd
  calibre mkvtoolnix-gui vlc qbittorrent localsend yacreader-poppler torbrowser-launcher spicetify-bin
  sddm-silent-theme git breeze-icons konsole kate
  neovim tmux npm yarn uv prettier markdownlint-cli2 yamllint meld wl-clipboard opencode-beta ollama
  jq imagemagick handbrake-full nvtop nvidia-prime rog-control-center btop cava pacman-contrib"
# test/container.sh sets CHEZMOI_SKIP_COMPILED: these AUR packages build from source and take very long
if [ -n "${CHEZMOI_SKIP_COMPILED:-}" ]; then
  for p in yacreader-poppler handbrake-full; do pkgs=$(echo "$pkgs" | sed "s/ $p\b//"); done
fi
# AUR packages; --noconfirm skips PKGBUILD review. yay keeps going past failed builds;
# don't fail the script on them, or chezmoi aborts the apply before writing any dotfiles.
# shellcheck disable=SC2086
yay -S --needed --noconfirm $pkgs || true
# shellcheck disable=SC2086
missing=$(pacman -T $pkgs || true)
# reported at the very end of the apply by run_after_zz-report-missing-packages.sh
list="${XDG_STATE_HOME:-$HOME/.local/state}/chezmoi-missing-packages"
if [ -n "$missing" ]; then mkdir -p "$(dirname "$list")"; echo "$missing" > "$list"; fi
