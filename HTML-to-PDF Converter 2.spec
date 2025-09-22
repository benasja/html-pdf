# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['html_to_pdf_app.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=['playwright', 'playwright.sync_api'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='HTML-to-PDF Converter',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='HTML-to-PDF Converter',
)
app = BUNDLE(
    coll,
    name='HTML-to-PDF Converter.app',
    icon=None,
    bundle_identifier=None,
)
