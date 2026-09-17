#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="$PWD/.local-data"
export XDG_CACHE_HOME="$PWD/.cache"
GODOT_BIN="${GODOT:-godot}"
"$GODOT_BIN" --headless --editor --path . --quit
"$GODOT_BIN" --headless --path . --script res://tests/smoke_test.gd
