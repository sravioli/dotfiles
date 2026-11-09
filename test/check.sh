#!/bin/sh
# Fast checks (seconds): renders every script template, syntax-checks every script, then applies the
# dotfiles into a throwaway home with scripts off. Touches nothing in your real home or chezmoi state.
set -eu
# git sets this while committing; chezmoi's external clones would otherwise write into the commit's index
unset GIT_INDEX_FILE
repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/home"; touch "$tmp/chezmoi.toml"
cm() {
  chezmoi --source "$repo" --destination "$tmp/home" --config "$tmp/chezmoi.toml" \
    --persistent-state "$tmp/state.boltdb" --cache "$tmp/cache" "$@"
}

for f in "$repo"/.chezmoiscripts/*; do
  echo "script: ${f#"$repo"/}"
  case $f in
    *.tmpl) cm execute-template < "$f" > "$tmp/script" ;;
    *) cp "$f" "$tmp/script" ;;
  esac
  sh -n "$tmp/script"
  if command -v shellcheck >/dev/null; then shellcheck -s sh "$tmp/script"; fi
done

echo "apply into a temporary home"
cm apply --exclude scripts
# repo-only folders must stay out of $HOME (.chezmoiignore)
for d in test zen README.md; do
  [ ! -e "$tmp/home/$d" ] || { echo "$d was deployed to \$HOME; add it to .chezmoiignore"; exit 1; }
done
echo "ok"
