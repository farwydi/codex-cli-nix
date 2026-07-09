#!/usr/bin/env bash
# Regenerate sources.json with the latest Codex CLI version and per-system hashes.
# Pin a version with: ./update.sh 0.144.0
set -euo pipefail
cd "$(dirname "$0")"

ver="${1:-$(curl -fsSL https://api.github.com/repos/openai/codex/releases/latest | jq -r .tag_name | sed 's/^rust-v//')}"
[ -n "$ver" ] && [ "$ver" != "null" ] || { echo "could not determine latest version" >&2; exit 1; }

# system -> release target triple (bundle = codex + codex-code-mode-host + bwrap)
systems="x86_64-linux:x86_64-unknown-linux-musl aarch64-linux:aarch64-unknown-linux-musl"

json=$(jq -n --arg version "$ver" '{version: $version, systems: {}}')
for entry in $systems; do
  sys="${entry%%:*}"; target="${entry#*:}"
  url="https://github.com/openai/codex/releases/download/rust-v$ver/codex-$target-bundle.tar.zst"
  hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
  json=$(jq --arg s "$sys" --arg t "$target" --arg h "$hash" \
    '.systems[$s] = {target: $t, hash: $h}' <<<"$json")
done

printf '%s\n' "$json" > sources.json
echo "updated to $ver"
