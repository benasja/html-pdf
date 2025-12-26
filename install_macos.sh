#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "$0")"; pwd)"
cd "$PROJECT_DIR"

APP_NAME="HTML-to-PDF Converter"
APP_BUNDLE="HTML_to_PDF_Converter.app"
BUILD_DIR="dist"
APP_PATH="${BUILD_DIR}/${APP_BUNDLE}"
INSTALL_DIR="${HOME}/Applications"
INSTALL_PATH="${INSTALL_DIR}/${APP_BUNDLE}"

echo "Building ${APP_NAME} for macOS..."

if [ ! -d "${APP_PATH}" ]; then
    echo "App not found. Building..."
    chmod +x build_app.sh
    ./build_app.sh
fi

if [ ! -d "${APP_PATH}" ]; then
    echo "Error: Failed to build app at ${APP_PATH}"
    exit 1
fi

echo "Signing app to remove Gatekeeper warnings..."

xattr -cr "${APP_PATH}" 2>/dev/null || true

codesign --force --deep --sign - "${APP_PATH}" 2>/dev/null || {
    echo "Warning: codesign failed, but continuing..."
}

echo "Installing to ${INSTALL_DIR}..."

mkdir -p "${INSTALL_DIR}"

if [ -d "${INSTALL_PATH}" ]; then
    echo "Removing existing installation..."
    rm -rf "${INSTALL_PATH}"
fi

cp -R "${APP_PATH}" "${INSTALL_PATH}"

xattr -cr "${INSTALL_PATH}" 2>/dev/null || true

codesign --force --deep --sign - "${INSTALL_PATH}" 2>/dev/null || {
    echo "Warning: codesign failed, but app should still work..."
}

echo ""
echo "✓ ${APP_NAME} installed successfully!"
echo "  Location: ${INSTALL_PATH}"
echo ""
echo "You can now launch it from Applications or Spotlight without warnings."

