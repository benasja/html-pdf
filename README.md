# HTML-to-PDF Converter

A cross-platform GUI app that converts pasted HTML into high-fidelity outputs using Playwright (Chromium) and a modern CustomTkinter UI.

Supported conversions:
- HTML → PDF (paged or continuous)
- HTML → DOCX (image-embedded)
- HTML → PPTX (image-embedded)

## Download

**Ready-to-use releases are available on the [Releases page](https://github.com/YOUR_USERNAME/html-pdf/releases).**

> **Note**: Replace `YOUR_USERNAME` with your actual GitHub username in the URL above.

- **macOS**: Download the `.zip` or `.dmg` file, extract it, and drag the app to your Applications folder.
- **Windows**: Download the `.zip` file, extract it, and run `HTML_to_PDF_Converter.exe`.

## Requirements
- **macOS**: macOS 12+ or **Windows**: Windows 10+
- Python 3.10+ (only needed for building from source)

## Quick Start (Run from source)

**macOS/Linux:**
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m playwright install chromium --with-deps
python html_to_pdf_app.py
```

**Windows:**
```cmd
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python -m playwright install chromium
python html_to_pdf_app.py
```

## Build a standalone app

**macOS:**
```bash
chmod +x build_app.sh
./build_app.sh
```
The app bundle will be created at `dist/HTML_to_PDF_Converter/HTML_to_PDF_Converter.app`.

**Windows:**
```cmd
build_app.bat
```
The executable will be created at `dist\HTML_to_PDF_Converter\HTML_to_PDF_Converter.exe`.

## Create a release package

**macOS:**
```bash
chmod +x build_release.sh
./build_release.sh
```
This creates a `.zip` file (and optionally a `.dmg` if `create-dmg` is installed) in the `dist/` directory.

**Windows:**
```cmd
build_release.bat
```
This creates a `.zip` file in the `dist\` directory.

## Notes
- The app uses Playwright's headless Chromium to render HTML accurately, including external CSS/JS and images.
- First run may download browser binaries.
- If PDF generation fails, check the error dialog for details.
