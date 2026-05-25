#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build/derived-data}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/dist}"
APP_NAME="TextExtractor.app"

cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "error: xcodegen is required. Install it with: brew install xcodegen" >&2
    exit 1
fi

echo "Generating Xcode project..."
xcodegen generate

echo "Building $APP_NAME ($CONFIGURATION)..."
xcodebuild \
    -project TextExtractor.xcodeproj \
    -scheme TextExtractor \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build

APP_SOURCE="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME"

if [[ ! -d "$APP_SOURCE" ]]; then
    echo "error: expected app bundle was not produced at $APP_SOURCE" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR/$APP_NAME"
cp -R "$APP_SOURCE" "$OUTPUT_DIR/$APP_NAME"

echo "App bundle ready at: $OUTPUT_DIR/$APP_NAME"