#!/bin/sh
# oh-my-posh isn't packaged for CachyOS; the upstream installer drops it in ~/bin (fish adds that to PATH) (themes come from .chezmoiexternal.toml).
# Runs once: `system-upgrade` keeps it current afterwards. Skips when already installed.
# shortcut: a failed download only warns, so a flaky network doesn't abort the apply. The installer goes to a file first so a failed curl isn't masked by bash. Rerun with `chezmoi state delete-bucket --bucket=scriptState` to retry.
set -eu
if [ -x "$HOME/bin/oh-my-posh" ] || command -v oh-my-posh >/dev/null 2>&1; then exit 0; fi
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
if curl -fsSL -o "$tmp" https://ohmyposh.dev/install.sh; then
    bash -s < "$tmp"
else
    echo "oh-my-posh install failed; run: curl -s https://ohmyposh.dev/install.sh | bash -s"
fi
