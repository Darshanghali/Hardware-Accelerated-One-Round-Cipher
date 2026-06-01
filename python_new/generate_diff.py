import tkinter as tk
from tkinter import filedialog, messagebox
from PIL import Image, ImageTk, ImageChops, ImageOps

class ImageDiffApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Image Difference Tool with Save")
        self.root.geometry("1000x600")  # Made slightly wider for the new button
        
        # Variables to store the actual image data
        self.img1_path = None
        self.img2_path = None
        self.original_image_1 = None
        self.original_image_2 = None
        self.diff_image = None  # New variable to hold the result for saving

        # --- Top Control Bar ---
        control_frame = tk.Frame(root, pady=10)
        control_frame.pack(side=tk.TOP, fill=tk.X)

        # Button 1: Load Original
        btn_1 = tk.Button(control_frame, text="1. Select Original", command=self.load_image1, height=2)
        btn_1.pack(side=tk.LEFT, padx=10, expand=True, fill=tk.X)

        # Button 2: Load Modified
        btn_2 = tk.Button(control_frame, text="2. Select Modified", command=self.load_image2, height=2)
        btn_2.pack(side=tk.LEFT, padx=10, expand=True, fill=tk.X)

        # Button 3: Run
        btn_run = tk.Button(control_frame, text="3. Run Comparison", command=self.process_diff, bg="#dddddd", height=2)
        btn_run.pack(side=tk.LEFT, padx=10, expand=True, fill=tk.X)

        # Button 4: Save (New!)
        # We keep a reference to this button (self.btn_save) so we can enable/disable it
        self.btn_save = tk.Button(control_frame, text="💾 Save Result", command=self.save_result, bg="#90ee90", height=2, state=tk.DISABLED)
        self.btn_save.pack(side=tk.LEFT, padx=10, expand=True, fill=tk.X)

        # --- Main Display Area ---
        display_frame = tk.Frame(root)
        display_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Image 1 Display
        self.lbl_img1 = tk.Label(display_frame, text="Original Image", relief="groove", bg="white")
        self.lbl_img1.grid(row=0, column=0, padx=5, pady=5, sticky="nsew")

        # Image 2 Display
        self.lbl_img2 = tk.Label(display_frame, text="Modified Image", relief="groove", bg="white")
        self.lbl_img2.grid(row=0, column=1, padx=5, pady=5, sticky="nsew")

        # Result Display
        self.lbl_result = tk.Label(display_frame, text="Difference Map\n(Run comparison to see)", relief="sunken", bg="#f0f0f0")
        self.lbl_result.grid(row=0, column=2, padx=5, pady=5, sticky="nsew")

        # Configure grid weights
        display_frame.grid_columnconfigure(0, weight=1)
        display_frame.grid_columnconfigure(1, weight=1)
        display_frame.grid_columnconfigure(2, weight=1)
        display_frame.grid_rowconfigure(0, weight=1)

    def load_image1(self):
        path = filedialog.askopenfilename(filetypes=[("Images", "*.png;*.jpg;*.jpeg;*.bmp")])
        if path:
            self.img1_path = path
            img = Image.open(path)
            self.original_image_1 = img
            self.display_image(img, self.lbl_img1)

    def load_image2(self):
        path = filedialog.askopenfilename(filetypes=[("Images", "*.png;*.jpg;*.jpeg;*.bmp")])
        if path:
            self.img2_path = path
            img = Image.open(path)
            self.original_image_2 = img
            self.display_image(img, self.lbl_img2)

    def display_image(self, img, label_widget):
        # Resize image to fit thumbnail for UI display (keep aspect ratio)
        display_size = (280, 400)
        img_copy = img.copy()
        img_copy.thumbnail(display_size)
        photo = ImageTk.PhotoImage(img_copy)
        
        # Keep a reference to prevent garbage collection
        label_widget.config(image=photo, text="")
        label_widget.image = photo

    def process_diff(self):
        if not self.original_image_1 or not self.original_image_2:
            messagebox.showwarning("Missing Inputs", "Please upload both images first.")
            return

        try:
            img1 = self.original_image_1.convert("RGB")
            img2 = self.original_image_2.convert("RGB")

            # Auto-resize img2 if dimensions don't match
            if img1.size != img2.size:
                img2 = img2.resize(img1.size)

            # --- CALCULATE DIFFERENCE ---
            diff = ImageChops.difference(img1, img2)
            
            # Boost contrast
            diff = ImageOps.autocontrast(diff, cutoff=0)

            # Store the result in a class variable so we can save it later
            self.diff_image = diff

            # Display Result
            self.display_image(diff, self.lbl_result)
            
            # Enable the save button now that we have a result
            self.btn_save.config(state=tk.NORMAL)
            
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {e}")

    def save_result(self):
        if self.diff_image:
            # Open Save Dialog
            file_path = filedialog.asksaveasfilename(
                defaultextension=".png",
                filetypes=[("PNG file", "*.png"), ("JPEG file", "*.jpg"), ("All Files", "*.*")],
                title="Save Difference Map"
            )
            
            if file_path:
                try:
                    self.diff_image.save(file_path)
                    messagebox.showinfo("Success", f"Image saved successfully to:\n{file_path}")
                except Exception as e:
                    messagebox.showerror("Save Error", f"Could not save image: {e}")

# --- Run the App ---
if __name__ == "__main__":
    root = tk.Tk()
    app = ImageDiffApp(root)
    root.mainloop()
