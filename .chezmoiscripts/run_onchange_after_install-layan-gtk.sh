#!/bin/sh
# Layan GTK isn't packaged (AUR one is 5 years stale); pinned upstream commit, bump SHA to update.
set -eu
SHA=745bf9ad74ddd2540c8917965c1130ffedeff5a3
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fsSL "https://github.com/vinceliuice/Layan-gtk-theme/archive/$SHA.tar.gz" | tar -xz -C "$tmp" --strip-components=1
mkdir -p "$HOME/.themes"  # upstream install.sh refuses a missing dest
"$tmp/install.sh" -d "$HOME/.themes"
