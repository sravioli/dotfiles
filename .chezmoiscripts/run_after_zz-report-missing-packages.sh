#!/bin/sh
# Runs last on every apply: lists packages install-kde-deps.sh couldn't install, until they're installed.
list="${XDG_STATE_HOME:-$HOME/.local/state}/chezmoi-missing-packages"
[ -f "$list" ] || exit 0
# shellcheck disable=SC2046
missing=$(pacman -T $(cat "$list") || true)
if [ -z "$missing" ]; then rm -f "$list"; exit 0; fi
echo "$missing" > "$list"
printf '\n\033[1;33mThese packages failed to install; install them by hand:\033[0m\n%s\n\n' "$missing"
