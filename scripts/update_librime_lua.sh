#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
target=skills/rime-lua/assets/librime.lua
url=https://raw.githubusercontent.com/hchunhui/librime-lua/master/contrib/librime.lua
tmp=$(mktemp "$target.XXXXXX")
trap 'rm -f "$tmp"' EXIT HUP INT TERM

curl --fail --location --silent --show-error "$url" -o "$tmp"
grep -q '^---@meta rime$' "$tmp"
chmod 644 "$tmp"
mv "$tmp" "$target"
echo "Updated $target"
