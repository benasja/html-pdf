@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

set "APP_NAME=HTML-to-PDF Converter"
set "BUILD_DIR=dist"
set "APP_DIR=%BUILD_DIR%\HTML_to_PDF_Converter"
set "APP_EXE=%APP_DIR%\HTML_to_PDF_Converter.exe"

if not exist "%APP_EXE%" (
    echo Error: %APP_EXE% not found. Run build_app.bat first.
    exit /b 1
)

if exist "VERSION" (
    set /p VERSION=<VERSION
    set "VERSION=!VERSION: =!"
) else (
    set "VERSION=1.0.0"
)

set "RELEASE_NAME=HTML-to-PDF_Converter-%VERSION%-Windows"
set "ZIP_FILE=%BUILD_DIR%\%RELEASE_NAME%.zip"

echo Packaging %APP_NAME% version %VERSION%...

cd "%BUILD_DIR%"

if exist "%RELEASE_NAME%.zip" del /q "%RELEASE_NAME%.zip"

powershell -Command "Compress-Archive -Path '%APP_DIR%\*' -DestinationPath '%ZIP_FILE%' -Force"

cd ..

echo.
echo Release package created:
echo   - %ZIP_FILE%

