#!/usr/bin/env bash
#
# screenshot.sh — Build, launch simulator, load watch face, and capture a screenshot.
#
# Usage:
#   ./screenshot.sh                   # Full pipeline: build → simulator → load → screenshot
#   ./screenshot.sh --capture-only    # Just capture (simulator already running with watch face)
#   ./screenshot.sh -o my-shot.png    # Specify output filename
#
# The script:
#   1. Builds the watch face with monkeyc
#   2. Ensures the Connect IQ simulator is running (launches if needed)
#   3. Loads the watch face into the simulator with monkeydo
#   4. Brings the simulator window to the front
#   5. Captures a screenshot of the simulator window
#
# Requirements:
#   - Garmin Connect IQ SDK installed
#   - Developer key stored in 1Password (see README → Build for setup)
#   - Terminal must have Screen Recording + Accessibility permissions

set -euo pipefail

KEY_REF="${KEY_REF:-op://Private/Garmin developer key/developer_key}"
SDK_DIR="${SDK_DIR:-$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.1.1-2025-03-27-66dae750f}"
DEVICE="fr955"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="$PROJECT_DIR/screenshot.png"
CAPTURE_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --capture-only) CAPTURE_ONLY=true; shift ;;
        -o) OUTPUT="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--capture-only] [-o output.png]"
            echo ""
            echo "Options:"
            echo "  --capture-only   Skip build/launch, just capture the simulator window"
            echo "  -o FILE          Output filename (default: screenshot.png)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

capture_simulator() {
    echo "📸 Capturing simulator window..."

    # Bring simulator to front
    osascript -e 'tell application "System Events" to set frontmost of process "simulator" to true' 2>/dev/null
    sleep 0.5

    # Get window position and size dynamically
    local rect
    rect=$(osascript -e '
        tell application "System Events"
            tell process "simulator"
                set {x, y} to position of window 1
                set {w, h} to size of window 1
                return "" & x & "," & y & "," & w & "," & h
            end tell
        end tell
    ' 2>&1)

    if [[ -z "$rect" || "$rect" == *"error"* ]]; then
        echo "❌ Could not get simulator window geometry. Is the simulator running?"
        exit 1
    fi

    screencapture -R "$rect" -o "$OUTPUT"
    echo "✅ Screenshot saved to $OUTPUT ($(du -h "$OUTPUT" | cut -f1 | xargs))"
}

if $CAPTURE_ONLY; then
    capture_simulator
    exit 0
fi

# Step 1: Build
echo "🔨 Building watch face..."
cd "$PROJECT_DIR"

# Fetch signing key from 1Password into a temp file, removed on exit.
# `--out-file` is binary-safe (plain `op read` would UTF-8-mangle the DER).
DEV_KEY=$(mktemp)
trap 'rm -f "$DEV_KEY"' EXIT
op read --out-file "$DEV_KEY" --force "$KEY_REF" > /dev/null

"$SDK_DIR/bin/monkeyc" -o bin/TwentyFourHour.prg -f monkey.jungle -y "$DEV_KEY" -d "$DEVICE"
echo "   Build successful"

# Step 2: Ensure simulator is running
if ! pgrep -f "ConnectIQ.app/Contents/MacOS/simulator" > /dev/null 2>&1; then
    echo "🚀 Launching simulator..."
    "$SDK_DIR/bin/ConnectIQ.app/Contents/MacOS/simulator" &
    sleep 8
    echo "   Simulator started"
else
    echo "✓  Simulator already running"
fi

# Step 3: Load watch face (monkeydo stays connected to the simulator, so
# redirect its output and disown immediately)
echo "📲 Loading watch face into simulator..."
"$SDK_DIR/bin/monkeydo" bin/TwentyFourHour.prg "$DEVICE" > /dev/null 2>&1 &
disown $! 2>/dev/null || true
sleep 3

# Step 4: Capture
capture_simulator

echo "🎉 Done!"
