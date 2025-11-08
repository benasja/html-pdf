
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

        print("SUCCESS: GUI components created")

        # Don't show window in headless environments
        root.withdraw()
        root.destroy()

        print("SUCCESS: Test completed")

    except Exception as e:
        print(f"FAILED: GUI test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
