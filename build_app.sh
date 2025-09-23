#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "$0")"; pwd)"
cd "$PROJECT_DIR"

python3 -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip wheel setuptools
pip install -r requirements.txt

# Install browser binaries for Playwright (Chromium)
python -m playwright install chromium --with-deps || true

# Build the .app using PyInstaller
rm -rf build dist "HTML-to-PDF Converter.spec" || true
pyinstaller \
  --noconfirm \
  --name "HTML_to_PDF_Converter" \
  --windowed \
  --hidden-import playwright \
  --hidden-import playwright.sync_api \
  html_to_pdf_app.py

echo "\nBuilt app at: dist/HTML_to_PDF_Converter/HTML_to_PDF_Converter.app"

