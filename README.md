# HTML-to-PDF Converter (macOS .app)

A simple macOS GUI app that converts pasted HTML into a high-fidelity PDF using Playwright (Chromium) and a modern CustomTkinter UI.

## Requirements
- macOS 12+
- Python 3.10+

## Quick Start (Run from source)
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m playwright install chromium --with-deps
python html_to_pdf_app.py
```

## Build a standalone .app
```bash
chmod +x build_app.sh
./build_app.sh
```
The app bundle will be created at `dist/HTML-to-PDF Converter.app`.

## Notes
- The app uses Playwright's headless Chromium to render HTML accurately, including external CSS/JS and images.
- First run may download browser binaries.
- If PDF generation fails, check the error dialog for details.
