#!/usr/bin/env bash

# Finds an available simulator UUID and writes `SIM_UDID=<UUID>` to GITHUB_ENV.
#
# Required variables:
# - SIMULATOR_NAME: device name, for example "iPhone 16"
# - SIMULATOR_OS: iOS runtime version, for example "26.2"
# - GITHUB_ENV: destination file for SIM_UDID (GitHub Actions provides this)
#
# GitHub Actions:
#   run: scripts/resolve_simulator_udid.sh
#
# Local macOS usage (with the selected Simulator runtime installed):
#   ENV_FILE="$(mktemp)"
#   SIMULATOR_NAME="iPhone 16" SIMULATOR_OS="26.2" GITHUB_ENV="$ENV_FILE" scripts/resolve_simulator_udid.sh
#   source "$ENV_FILE" && export SIM_UDID
#   rm "$ENV_FILE"

set -euo pipefail

: "${SIMULATOR_NAME:?SIMULATOR_NAME must be set}"
: "${SIMULATOR_OS:?SIMULATOR_OS must be set}"
: "${GITHUB_ENV:?GITHUB_ENV must be set}"

if ! udid="$(
  xcrun simctl list devices available |
    grep -A 20 "iOS ${SIMULATOR_OS}" |
    grep -m 1 "^ *${SIMULATOR_NAME} (" |
    sed -nE 's/.*\(([A-F0-9-]+)\).*/\1/p'
)"; then
  echo "::error::${SIMULATOR_NAME} (iOS ${SIMULATOR_OS}) simulator not found."
  exit 1
fi

if [[ ! "$udid" =~ ^[A-F0-9-]{36}$ ]]; then
  echo "::error::Could not extract a valid UUID for ${SIMULATOR_NAME} (iOS ${SIMULATOR_OS})."
  exit 1
fi

echo "SIM_UDID=$udid" >> "$GITHUB_ENV"
