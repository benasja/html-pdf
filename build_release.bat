@echo off
setlocal enabledelayedexpansion

set PROJECT_DIR=%~dp0
cd /d "%PROJECT_DIR%"

set APP_NAME=HTML-to-PDF Converter
set APP_BUNDLE=HTML_to_PDF_Converter.exe
set BUILD_DIR=dist
set APP_DIR=%BUILD_DIR%\HTML_to_PDF_Converter
set APP_PATH=%APP_DIR%\%APP_BUNDLE%

if not exist "%APP_PATH%" (
    echo Error: %APP_PATH% not found. Run build_app.bat first.
    exit /b 1
)

if exist "VERSION" (
    set /p VERSION=<VERSION
    set VERSION=!VERSION: =!
) else (
    for /f "tokens=*" %%i in ('git describe --tags --abbrev=0 2^>nul') do set VERSION=%%i
    if "!VERSION!"=="" set VERSION=v1.0.0
    set VERSION=!VERSION:v=!
)

set RELEASE_NAME=%APP_NAME: =_%-%VERSION%-Windows
set ZIP_FILE=%BUILD_DIR%\%RELEASE_NAME%.zip

echo Packaging %APP_NAME% version %VERSION%...

cd %BUILD_DIR%

echo Creating ZIP archive...
if exist "%RELEASE_NAME%.zip" del /q "%RELEASE_NAME%.zip"

powershell -Command "Compress-Archive -Path '%APP_DIR%\*' -DestinationPath '%RELEASE_NAME%.zip' -Force"

if %ERRORLEVEL% EQU 0 (
    echo Created %ZIP_FILE%
) else (
    echo Failed to create ZIP archive
    exit /b 1
)

cd "%PROJECT_DIR%"

echo.
echo Release package created:
echo   - %ZIP_FILE%

