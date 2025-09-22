import os
import sys
import subprocess
import threading
import traceback
import tempfile
import webbrowser
from typing import Optional

import customtkinter as ctk
from tkinter import filedialog, messagebox


def _ensure_playwright_browsers() -> None:
    """Ensure Playwright Chromium is installed and discoverable at runtime.

    In PyInstaller bundles, Playwright may default to a package-local browsers
    directory that isn't shipped. We redirect to the user cache path and
    install Chromium there if not already present.
    """
    # Use the default user cache for Playwright browsers on macOS
    user_cache = os.path.expanduser("~/Library/Caches/ms-playwright")
    os.environ.setdefault("PLAYWRIGHT_BROWSERS_PATH", user_cache)

    chromium_installed_marker = os.path.join(user_cache, "chromium-*")
    # Best-effort detection; if directory not present, attempt install
    if not os.path.isdir(user_cache) or not any(
        name.startswith("chromium") for name in os.listdir(user_cache)
    ):
        try:
            subprocess.run(
                [sys.executable, "-m", "playwright", "install", "chromium"],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
        except Exception:
            # Let Playwright raise a clearer error later if install truly failed
            pass


def convert_html_to_pdf_sync(html_content: str, output_pdf_path: str) -> None:
    """Render HTML to PDF using Playwright (Chromium) synchronously.

    Args:
        html_content: The complete HTML string to render.
        output_pdf_path: Absolute path to write the resulting PDF file.
    """
    from playwright.sync_api import sync_playwright  # Imported here to start fast UI

    _ensure_playwright_browsers()
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        # Use screen media; wait for network to be idle so external CSS/images load
        page.emulate_media(media="screen")
        page.set_content(html_content, wait_until="networkidle")

        pdf_bytes = page.pdf(
            format="A4",
            print_background=True,
            prefer_css_page_size=True,
        )

        with open(output_pdf_path, "wb") as f:
            f.write(pdf_bytes)

        context.close()
        browser.close()


class HtmlToPdfApp(ctk.CTk):
    def __init__(self) -> None:
        super().__init__()

        self.title("HTML-to-PDF Converter")
        self.geometry("900x700")
        self.minsize(700, 500)

        ctk.set_appearance_mode("System")
        ctk.set_default_color_theme("blue")

        # Layout configuration
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)
        self.grid_rowconfigure(1, weight=0)

        # Text input for HTML
        self.html_text = ctk.CTkTextbox(self, wrap="word")
        self.html_text.grid(row=0, column=0, padx=16, pady=(16, 8), sticky="nsew")

        # Bottom bar frame
        bottom = ctk.CTkFrame(self)
        bottom.grid(row=1, column=0, padx=16, pady=(0, 16), sticky="ew")
        bottom.grid_columnconfigure(0, weight=1)
        bottom.grid_columnconfigure(1, weight=0)
        bottom.grid_columnconfigure(2, weight=0)

        # Status label
        self.status_var = ctk.StringVar(value="Ready")
        self.status_label = ctk.CTkLabel(bottom, textvariable=self.status_var, anchor="w")
        self.status_label.grid(row=0, column=0, padx=(12, 12), pady=12, sticky="w")

        # Preview button
        self.preview_btn = ctk.CTkButton(bottom, text="Preview HTML", command=self.on_preview_click)
        self.preview_btn.grid(row=0, column=1, padx=12, pady=12, sticky="e")

        # Convert button
        self.convert_btn = ctk.CTkButton(bottom, text="Convert to PDF", command=self.on_convert_click)
        self.convert_btn.grid(row=0, column=2, padx=12, pady=12, sticky="e")

        # Example placeholder
        self._insert_example_placeholder()

    def _insert_example_placeholder(self) -> None:
        placeholder = (
            "<!doctype html>\n"
            "<html>\n<head>\n<meta charset=\"utf-8\">\n"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
            "<title>Sample</title>\n"
            "<link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css\">\n"
            "</head>\n<body class=\"p-12\">\n"
            "<div class=\"prose\">\n"
            "  <h1 class=\"text-3xl font-bold\">HTML-to-PDF Converter</h1>\n"
            "  <p>Paste your HTML here or overwrite this example.</p>\n"
            "  <p><em>External CSS and images will be loaded.</em></p>\n"
            "</div>\n"
            "</body>\n</html>\n"
        )
        self.html_text.insert("1.0", placeholder)

    def on_convert_click(self) -> None:
        html = self.html_text.get("1.0", "end-1c").strip()
        if not html:
            messagebox.showinfo("No HTML", "Please paste HTML content before converting.")
            return

        output_path = filedialog.asksaveasfilename(
            title="Save PDF As...",
            defaultextension=".pdf",
            filetypes=[("PDF Files", "*.pdf")],
            initialfile="output.pdf",
        )

        if not output_path:
            return

        # Disable button and update status
        self.convert_btn.configure(state="disabled")
        self.status_var.set("Converting...")

        def worker() -> None:
            error_msg: Optional[str] = None
            try:
                convert_html_to_pdf_sync(html, output_path)
            except Exception:
                error_msg = traceback.format_exc()

            def finalize() -> None:
                if error_msg is None:
                    self.status_var.set("PDF saved successfully!")
                else:
                    self.status_var.set("Conversion failed. See details in alert.")
                    messagebox.showerror("Error", f"An error occurred during conversion:\n\n{error_msg}")
                self.convert_btn.configure(state="normal")

            self.after(0, finalize)

        threading.Thread(target=worker, daemon=True).start()

    def on_preview_click(self) -> None:
        html = self.html_text.get("1.0", "end-1c").strip()
        if not html:
            messagebox.showinfo("No HTML", "Please paste HTML content to preview.")
            return
        try:
            with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as tmp:
                tmp.write(html)
                tmp_path = tmp.name
            webbrowser.open(f"file://{tmp_path}")
            self.status_var.set("Opened preview in default browser")
        except Exception as exc:
            self.status_var.set("Failed to open preview")
            messagebox.showerror("Error", f"Could not open preview:\n\n{exc}")


def main() -> None:
    app = HtmlToPdfApp()
    app.mainloop()


if __name__ == "__main__":
    main()


