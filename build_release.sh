#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "$0")"; pwd)"
cd "$PROJECT_DIR"

APP_NAME="HTML-to-PDF Converter"
APP_BUNDLE="HTML_to_PDF_Converter.app"
BUILD_DIR="dist"
APP_DIR="${BUILD_DIR}/HTML_to_PDF_Converter"
APP_PATH="${APP_DIR}/${APP_BUNDLE}"

if [ ! -d "${APP_PATH}" ]; then
    echo "Error: ${APP_PATH} not found. Run build_app.sh first."
    exit 1
fi

if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION | tr -d '[:space:]')
else
    VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
    VERSION=${VERSION#v}
fi
RELEASE_NAME="${APP_NAME// /_}-${VERSION}-macOS"
ZIP_FILE="${BUILD_DIR}/${RELEASE_NAME}.zip"
DMG_FILE="${BUILD_DIR}/${RELEASE_NAME}.dmg"

echo "Packaging ${APP_NAME} version ${VERSION}..."

cd "${BUILD_DIR}"

echo "Creating ZIP archive..."
rm -f "${RELEASE_NAME}.zip"
cd "${APP_DIR}"
ditto -c -k --keepParent "${APP_BUNDLE}" "${RELEASE_NAME}.zip"
mv "${RELEASE_NAME}.zip" ..
cd ..
echo "✓ Created ${ZIP_FILE}"

if command -v create-dmg &> /dev/null; then
    echo "Creating DMG..."
    rm -f "${RELEASE_NAME}.dmg"
    create-dmg \
        --volname "${APP_NAME}" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --icon "${APP_BUNDLE}" 200 190 \
        --hide-extension "${APP_BUNDLE}" \
        --app-drop-link 600 185 \
        "${RELEASE_NAME}.dmg" \
        "${APP_DIR}"
    echo "✓ Created ${DMG_FILE}"
else
    echo "⚠ create-dmg not found. Skipping DMG creation."
    echo "  Install with: brew install create-dmg"
fi

cd "$PROJECT_DIR"

echo ""
echo "Release package created:"
echo "  - ${ZIP_FILE}"
[ -f "${DMG_FILE}" ] && echo "  - ${DMG_FILE}"

