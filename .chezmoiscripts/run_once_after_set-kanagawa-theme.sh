#!/bin/sh
# Applies the Kanagawa Wave global theme: Plasma style, splash, window decorations, cursor and so on.
# Plasma keeps what a global theme sets in ~/.config/kdedefaults, which isn't tracked here, so apply it
# instead of copying files. It runs once; to switch to dragon or lotus, apply that by hand or edit
# the name below, which re-runs the script.
# shortcut: needs a running Plasma session, so it's skipped without one; run the command by hand then.
theme=org.kanagawa-community.wave
if command -v plasma-apply-lookandfeel >/dev/null && pgrep -x plasmashell >/dev/null; then
  plasma-apply-lookandfeel -a "$theme" || echo "Could not apply $theme; pick it in System Settings > Appearance"
else
  echo "No Plasma session; run: plasma-apply-lookandfeel -a $theme"
fi
