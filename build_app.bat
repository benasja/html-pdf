@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

python -m venv .venv
call .venv\Scripts\activate.bat

python -m pip install --upgrade pip wheel setuptools
pip install -r requirements.txt

python -m playwright install chromium || echo Playwright install had issues, continuing...

if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist "HTML-to-PDF Converter.spec" del /q "HTML-to-PDF Converter.spec"

pyinstaller ^
  --noconfirm ^
  --name "HTML_to_PDF_Converter" ^
  --windowed ^
  --hidden-import playwright ^
  --hidden-import playwright.sync_api ^
  html_to_pdf_app.py

echo.
echo Built app at: dist\HTML_to_PDF_Converter\HTML_to_PDF_Converter.exe

