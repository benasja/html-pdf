from setuptools import setup


APP = ['html_to_pdf_app.py']
APP_NAME = 'HTML-to-PDF Converter'
DATA_FILES = []
OPTIONS = {
    'argv_emulation': True,
    'iconfile': None,
    'includes': [
        'playwright',
        'playwright.sync_api',
        'customtkinter',
        'tkinter',
    ],
    'packages': [
        'playwright',
    ],
    'plist': {
        'CFBundleName': APP_NAME,
        'CFBundleDisplayName': APP_NAME,
        'CFBundleShortVersionString': '1.0.0',
        'LSMinimumSystemVersion': '10.15.0',
        'NSHumanReadableCopyright': '© 2025',
    },
}


setup(
    app=APP,
    name=APP_NAME,
    data_files=DATA_FILES,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)


