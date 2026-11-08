#!/bin/sh
# Copies the Sine mods' settings from Zen's prefs.js into zen/mod-prefs.js. The keys come from each
# mod's preferences.json; API keys (Tidy Downloads' AI providers) are left out so they never reach git.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
cfg="$HOME/.config/zen"
profile=$(sed -n 's/^Default=//p' "$cfg/installs.ini" | head -1)
keys=$(for f in "$here"/sine-mods/*/preferences.json; do
  python3 -c 'import json,sys; [print(p["property"]) for p in json.load(open(sys.argv[1])) if isinstance(p, dict) and p.get("property")]' "$f"
done | grep -v 'api_key' | sort -u)
echo "$keys" | while IFS= read -r k; do grep -F "user_pref(\"$k\"," "$cfg/$profile/prefs.js" || true; done > "$here/mod-prefs.js"
echo "saved $(wc -l < "$here/mod-prefs.js") settings to zen/mod-prefs.js"
