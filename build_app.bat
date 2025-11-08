@echo off
setlocal enabledelayedexpansion

set PROJECT_DIR=%~dp0
cd /d "%PROJECT_DIR%"

python -m venv .venv
call .venv\Scripts\activate.bat

python -m pip install --upgrade pip wheel setuptools
pip install -r requirements.txt

python -m playwright install chromium || exit /b 1

rmdir /s /q build dist 2>nul
del /q "HTML-to-PDF Converter.spec" 2>nul

pyinstaller ^
  --noconfirm ^
  --name "HTML_to_PDF_Converter" ^
  --windowed ^
  --hidden-import playwright ^
  --hidden-import playwright.sync_api ^
  html_to_pdf_app.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Built app at: dist\HTML_to_PDF_Converter\HTML_to_PDF_Converter.exe
) else (
    echo Build failed!
    exit /b 1
)

