#!/usr/bin/env bash
set -euo pipefail

readonly GODOT_VERSION="4.4.1"
readonly GODOT_RELEASE="${GODOT_VERSION}-stable"
readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TOOLS_DIR="${PROJECT_DIR}/.tools/godot-${GODOT_RELEASE}"

if command -v godot >/dev/null 2>&1; then
	GODOT_BIN="$(command -v godot)"
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
	mkdir -p "${TOOLS_DIR}"
	GODOT_BIN="${TOOLS_DIR}/Godot_v${GODOT_RELEASE}_linux.x86_64"
	if [[ ! -x "${GODOT_BIN}" ]]; then
		curl --fail --location --silent --show-error \
			"https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}/Godot_v${GODOT_RELEASE}_linux.x86_64.zip" \
			--output "${TOOLS_DIR}/godot.zip"
		unzip -q -o "${TOOLS_DIR}/godot.zip" -d "${TOOLS_DIR}"
		chmod +x "${GODOT_BIN}"
	fi
	export XDG_DATA_HOME="${TOOLS_DIR}/data"
	TEMPLATE_DIR="${XDG_DATA_HOME}/godot/export_templates/${GODOT_VERSION}.stable"
	if [[ ! -f "${TEMPLATE_DIR}/web_nothreads_release.zip" ]]; then
		mkdir -p "${TEMPLATE_DIR}"
		curl --fail --location --silent --show-error \
			"https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}/Godot_v${GODOT_RELEASE}_export_templates.tpz" \
			--output "${TOOLS_DIR}/templates.tpz"
		unzip -q -o "${TOOLS_DIR}/templates.tpz" "templates/*" -d "${TOOLS_DIR}/template-archive"
		cp -R "${TOOLS_DIR}/template-archive/templates/." "${TEMPLATE_DIR}/"
	fi
else
	echo "Godot is not installed; install Godot ${GODOT_VERSION} or run this export on Linux x86_64." >&2
	exit 1
fi

mkdir -p "${PROJECT_DIR}/public"
find "${PROJECT_DIR}/public" -mindepth 1 ! -name .gitkeep -delete
"${GODOT_BIN}" --headless --path "${PROJECT_DIR}" --export-release Web "${PROJECT_DIR}/public/index.html"
