#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
DEST="$ROOT/.cache/web-validation"
mkdir -p "$DEST/tests" "$DEST/public"
cp ./*.gd ./*.tscn project.godot export_presets.cfg icon.svg "$DEST/"
cp tests/web_probe.gd "$DEST/tests/"
python3 - "$DEST/export_presets.cfg" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
p.write_text(p.read_text().replace('custom_features=""', 'custom_features="web_validation"').replace('public/*,tests/*,docs/*', 'public/*'))
PY
export XDG_DATA_HOME="$ROOT/.local-data"
export XDG_CACHE_HOME="$ROOT/.cache"
GODOT_BIN="${GODOT:-$ROOT/.tools/godot-4.5-stable/Godot_v4.5-stable_linux.x86_64}"
"$GODOT_BIN" --headless --editor --path "$DEST" --quit
"$GODOT_BIN" --headless --path "$DEST" --export-release Web "$DEST/public/index.html"
echo 'Serve .cache/web-validation/public on a separate localhost port. Never deploy this validation-only build.'
