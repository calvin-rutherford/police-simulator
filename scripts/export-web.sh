#!/usr/bin/env bash
set -euo pipefail

readonly GODOT_VERSION="4.5"
readonly GODOT_RELEASE="${GODOT_VERSION}-stable"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PROJECT_DIR
readonly TOOLS_DIR="${PROJECT_DIR}/.tools/godot-${GODOT_RELEASE}"
readonly RELEASE_URL="https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}"
export XDG_DATA_HOME="${PROJECT_DIR}/.local-data"
export XDG_CACHE_HOME="${PROJECT_DIR}/.cache"
mkdir -p "${TOOLS_DIR}" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}"

# Explicit override also avoids Snap launchers that cannot see hidden worktrees.
GODOT_BIN="${GODOT:-}"
if [[ -z "${GODOT_BIN}" ]]; then
	if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
		echo 'Set GODOT to your Godot 4.5 executable.' >&2
		exit 1
	fi
	GODOT_BIN="${TOOLS_DIR}/Godot_v${GODOT_RELEASE}_linux.x86_64"
	if [[ ! -x "${GODOT_BIN}" ]]; then
		curl --fail --location --retry 3 --silent --show-error "${RELEASE_URL}/Godot_v${GODOT_RELEASE}_linux.x86_64.zip" -o "${TOOLS_DIR}/godot.zip"
		unzip -q -o "${TOOLS_DIR}/godot.zip" -d "${TOOLS_DIR}"
		chmod +x "${GODOT_BIN}"
	fi
fi
[[ "$("${GODOT_BIN}" --version)" == 4.5.stable.* ]] || { echo 'Godot 4.5 stable required.' >&2; exit 1; }
TEMPLATE_DIR="${XDG_DATA_HOME}/godot/export_templates/${GODOT_VERSION}.stable"
if [[ ! -f "${TEMPLATE_DIR}/web_nothreads_release.zip" ]]; then
	mkdir -p "${TEMPLATE_DIR}"
	curl --fail --location --retry 3 --silent --show-error "${RELEASE_URL}/Godot_v${GODOT_RELEASE}_export_templates.tpz" -o "${TOOLS_DIR}/templates.tpz"
	unzip -q -o "${TOOLS_DIR}/templates.tpz" 'templates/web_nothreads_release.zip' 'templates/version.txt' -d "${TOOLS_DIR}"
	cp "${TOOLS_DIR}/templates/"* "${TEMPLATE_DIR}/"
	rm "${TOOLS_DIR}/templates.tpz"
fi
mkdir -p "${PROJECT_DIR}/public"
find "${PROJECT_DIR}/public" -mindepth 1 ! -name .gitkeep -delete
"${GODOT_BIN}" --headless --editor --path "${PROJECT_DIR}" --quit
"${GODOT_BIN}" --headless --path "${PROJECT_DIR}" --export-release Web "${PROJECT_DIR}/public/index.html"
# Production never exports the optional validation bridge.
if grep -q 'web_validation' "${PROJECT_DIR}/export_presets.cfg"; then
	echo 'Validation feature must not be set on the production preset.' >&2
	exit 1
fi
