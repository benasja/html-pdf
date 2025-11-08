
try:
    import customtkinter as ctk
    print("SUCCESS: customtkinter")
except ImportError as e:
    print(f"FAILED: customtkinter: {e}")

try:
    import playwright
    print("SUCCESS: playwright")
except ImportError as e:
    print(f"FAILED: playwright: {e}")

try:
    import docx
    print("SUCCESS: python-docx")
except ImportError as e:
    print(f"FAILED: python-docx: {e}")

try:
    import pptx
    print("SUCCESS: python-pptx")
except ImportError as e:
    print(f"FAILED: python-pptx: {e}")

try:
    from PIL import Image
    print("SUCCESS: Pillow")
except ImportError as e:
    print(f"FAILED: Pillow: {e}")

try:
    import tkinter
    print("SUCCESS: tkinter")
except ImportError as e:
    print(f"FAILED: tkinter: {e}")

print("Import tests completed")
