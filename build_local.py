#!/usr/bin/env python3
"""
Local build script for HTML-to-PDF Converter
Run this to test builds before pushing to GitHub Actions
"""

import os
import sys
import subprocess
import shutil
import platform

def run_command(cmd, description, cwd=None):
    """Run a command and return success/failure"""
    print(f"\n{'='*50}")
    print(f"🔧 {description}")
    print(f"📝 Command: {' '.join(cmd)}")
    print('='*50)

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,
            cwd=cwd
        )

        if result.returncode == 0:
            print(f"✅ {description} succeeded")
            return True, result.stdout, result.stderr
        else:
            print(f"❌ {description} failed (exit code: {result.returncode})")
            print("STDOUT (last 500 chars):")
            print(result.stdout[-500:] if result.stdout else "None")
            print("STDERR (last 500 chars):")
            print(result.stderr[-500:] if result.stderr else "None")
            return False, result.stdout, result.stderr

    except subprocess.TimeoutExpired:
        print(f"⏰ {description} timed out")
        return False, "", "Timeout"
    except Exception as e:
        print(f"💥 {description} error: {e}")
        return False, "", str(e)

def main():
    print(f"🚀 HTML-to-PDF Converter Build Test")
    print(f"📊 Platform: {platform.system()} {platform.release()}")
    print(f"🐍 Python: {sys.version}")

    # Clean up previous builds
    print("\n🧹 Cleaning up previous builds...")
    for path in ['build', 'dist', 'HTML-to-PDF Converter.spec']:
        if os.path.exists(path):
            if os.path.isdir(path):
                shutil.rmtree(path)
                print(f"  Removed directory: {path}")
            else:
                os.remove(path)
                print(f"  Removed file: {path}")

    # Step 1: Install/update pip and basic tools
    success, _, _ = run_command(
        [sys.executable, '-m', 'pip', 'install', '--upgrade', 'pip', 'wheel', 'setuptools'],
        "Upgrading pip and build tools"
    )
    if not success:
        print("❌ Failed to upgrade pip - exiting")
        return False

    # Step 2: Install PyInstaller
    success, _, _ = run_command(
        [sys.executable, '-m', 'pip', 'install', 'pyinstaller'],
        "Installing PyInstaller"
    )
    if not success:
        print("❌ Failed to install PyInstaller - exiting")
        return False

    # Step 3: Test PyInstaller
    success, _, _ = run_command(
        [sys.executable, '-m', 'PyInstaller', '--version'],
        "Testing PyInstaller installation"
    )
    if not success:
        print("❌ PyInstaller test failed - exiting")
        return False

    # Step 4: Install tkinter (if needed)
    try:
        import tkinter
        print("✅ tkinter is available")
    except ImportError:
        print("⚠️ tkinter not available - this might cause issues")
        # Try to install it
        run_command(
            [sys.executable, '-m', 'pip', 'install', 'tkinter'],
            "Attempting to install tkinter"
        )

    # Step 5: Create and test minimal app
    print("\n📝 Creating minimal test app...")
    minimal_code = '''
import tkinter as tk
import sys

def main():
    print("Testing minimal GUI app...")
    try:
        root = tk.Tk()
        root.title("Test App")
        root.geometry("300x200")

        label = tk.Label(root, text="Build Test Successful!")
        label.pack(pady=20)

        print("✓ GUI components created successfully")

        # Don't show window in headless environments
        root.withdraw()
        root.destroy()

        print("✓ Test completed successfully")

    except Exception as e:
        print(f"✗ GUI test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
'''

    with open('test_minimal.py', 'w') as f:
        f.write(minimal_code)

    # Test running the minimal app
    success, _, _ = run_command(
        [sys.executable, 'test_minimal.py'],
        "Testing minimal app execution"
    )

    # Step 6: Build minimal app
    success, _, _ = run_command(
        [sys.executable, '-m', 'PyInstaller', '--noconfirm', '--name', 'test_minimal', '--onedir', '--console', '--hidden-import', 'tkinter', 'test_minimal.py'],
        "Building minimal test app"
    )

    if not success:
        print("❌ Minimal build failed - PyInstaller issue")
        return False

    # Check if build succeeded
    if os.path.exists('dist/test_minimal'):
        print("✅ Minimal build created dist/test_minimal/")
        # List contents
        for root, dirs, files in os.walk('dist/test_minimal'):
            for file in files:
                if file.endswith('.exe'):
                    file_path = os.path.join(root, file)
                    size = os.path.getsize(file_path)
                    print(f"  📄 Executable: {file} ({size} bytes)")
    else:
        print("❌ Minimal build failed - no dist directory")
        return False

    # Step 7: Install main dependencies
    print("\n📦 Installing main application dependencies...")
    deps = ['customtkinter', 'playwright', 'python-docx', 'python-pptx', 'Pillow']

    for dep in deps:
        success, _, _ = run_command(
            [sys.executable, '-m', 'pip', 'install', dep],
            f"Installing {dep}"
        )
        if not success:
            print(f"⚠️ Failed to install {dep} - continuing anyway")

    # Step 8: Install Playwright browsers
    success, _, _ = run_command(
        [sys.executable, '-m', 'playwright', 'install', 'chromium'],
        "Installing Playwright browsers"
    )

    # Step 9: Test main app imports
    print("\n🔍 Testing main application imports...")
    test_imports = '''
try:
    import customtkinter as ctk
    print("✓ customtkinter")
except ImportError as e:
    print(f"✗ customtkinter: {e}")

try:
    import playwright
    print("✓ playwright")
except ImportError as e:
    print(f"✗ playwright: {e}")

try:
    import docx
    print("✓ python-docx")
except ImportError as e:
    print(f"✗ python-docx: {e}")

try:
    import pptx
    print("✓ python-pptx")
except ImportError as e:
    print(f"✗ python-pptx: {e}")

try:
    from PIL import Image
    print("✓ Pillow")
except ImportError as e:
    print(f"✗ Pillow: {e}")

try:
    import tkinter
    print("✓ tkinter")
except ImportError as e:
    print(f"✗ tkinter: {e}")

print("Import tests completed")
'''

    with open('test_imports.py', 'w') as f:
        f.write(test_imports)

    run_command(
        [sys.executable, 'test_imports.py'],
        "Testing dependency imports"
    )

    # Step 10: Build main application
    print("\n🏗️ Building main application...")
    success, _, _ = run_command(
        [sys.executable, '-m', 'PyInstaller',
         '--noconfirm',
         '--name', 'HTML_to_PDF_Converter',
         '--onedir',
         '--windowed',
         '--hidden-import', 'customtkinter',
         '--hidden-import', 'tkinter',
         '--hidden-import', 'playwright',
         '--hidden-import', 'playwright.sync_api',
         '--hidden-import', 'PIL',
         '--hidden-import', 'docx',
         '--hidden-import', 'pptx',
         'html_to_pdf_app.py'],
        "Building main HTML-to-PDF Converter application"
    )

    # Step 11: Verify main build
    if success and os.path.exists('dist/HTML_to_PDF_Converter'):
        print("✅ Main application build succeeded!")

        # Count executables
        exe_count = 0
        total_size = 0
        for root, dirs, files in os.walk('dist/HTML_to_PDF_Converter'):
            for file in files:
                if file.endswith('.exe'):
                    exe_count += 1
                    file_path = os.path.join(root, file)
                    size = os.path.getsize(file_path)
                    total_size += size
                    print(f"  📄 Executable: {file} ({size} bytes)")

        print(f"📊 Build summary: {exe_count} executables, {total_size} total bytes")

        # Step 12: Create release package
        version = "1.0.0"
        if os.path.exists('VERSION'):
            with open('VERSION', 'r') as f:
                version = f.read().strip()

        release_name = f"HTML-to-PDF_Converter-{version}-Windows"
        zip_path = f"{release_name}.zip"

        print(f"\n📦 Creating release package: {zip_path}")
        shutil.make_archive(release_name, 'zip', 'dist/HTML_to_PDF_Converter')

        if os.path.exists(zip_path):
            zip_size = os.path.getsize(zip_path)
            print(f"✅ Release package created: {zip_size} bytes")
            print(f"📁 Package: {zip_path}")
        else:
            print("❌ Failed to create release package")

        print("\n🎉 BUILD COMPLETED SUCCESSFULLY!")
        print("You can now distribute the ZIP file to users.")
        return True

    else:
        print("❌ Main application build failed")
        if os.path.exists('dist'):
            print("Contents of dist directory:")
            for item in os.listdir('dist'):
                item_path = os.path.join('dist', item)
                if os.path.isdir(item_path):
                    print(f"  📁 {item}/")
                else:
                    size = os.path.getsize(item_path)
                    print(f"  📄 {item} ({size} bytes)")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
