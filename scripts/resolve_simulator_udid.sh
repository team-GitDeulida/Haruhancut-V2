#!/usr/bin/env bash

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
