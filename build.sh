#!/usr/bin/env bash
#
# build.sh — Compile the watch face, fetching the signing key from 1Password.
#
# Usage:
#   ./build.sh                 # Release .iq package for all devices in manifest.xml
#   ./build.sh --debug         # Debug .prg for fr955 (use with the simulator)
#
# Environment:
#   KEY_REF    op:// reference to the base64-encoded developer key
#              (default: op://Private/garmin-developer-key/password)
#   SDK_DIR    Connect IQ SDK install path
#
# One-time setup of the 1Password item is documented in README.md (Build).

set -euo pipefail

KEY_REF="${KEY_REF:-op://Private/garmin-developer-key/password}"
SDK_DIR="${SDK_DIR:-$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.1.1-2025-03-27-66dae750f}"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

if [[ ! -x "$SDK_DIR/bin/monkeyc" ]]; then
    echo "error: monkeyc not found at $SDK_DIR/bin/monkeyc" >&2
    echo "       set SDK_DIR or install the Connect IQ SDK" >&2
    exit 1
fi

# Materialize the signing key from 1Password into a temp file and clean it
# up on exit. The key is stored base64-encoded so it survives op's text
# field; we decode it back to raw DER here.
KEY=$(mktemp)
trap 'rm -f "$KEY"' EXIT
op read "$KEY_REF" | base64 -d > "$KEY"

if [[ "${1:-}" == "--debug" ]]; then
    "$SDK_DIR/bin/monkeyc" -f monkey.jungle -o bin/TwentyFourHour.prg \
        -y "$KEY" -d fr955 -w
    echo "Debug build: bin/TwentyFourHour.prg"
else
    "$SDK_DIR/bin/monkeyc" -f monkey.jungle -o bin/TwentyFourHour.iq \
        -y "$KEY" -e -r
    echo "Release build: bin/TwentyFourHour.iq"
fi
