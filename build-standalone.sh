#!/usr/bin/env bash
# Build an all-in-one script to use Bashtion with it's standard library, ready to go.
# Do not use this file in your own scripts! Only import things you need, probably not *everything*.

set -euxo pipefail
shopt -s globstar nullglob

cd "$(dirname "$0")"
output_file=./try-bashtion.sh

BASHTION_CACHE=./cache
BASHTION=./cache/bashtion
ln -sf "$PWD/out/bashtion-$(uname -s)-$(uname -m)" "$BASHTION"
source bashtion.sh

{
cat bashtion.sh
set +x
for f in ./lib/utils/**/*.sh; do
    bashtion run namespace output "$f"
    echo "$output" | grep -v '^import '
done
} > "$output_file"
echo Done!
