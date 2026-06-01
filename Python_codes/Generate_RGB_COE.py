import argparse
from PIL import Image
import numpy as np
import os

pixel_count = 0

# Set up argument parsing
parser = argparse.ArgumentParser(description="Convert an image to a .coe file with pixel data in hexadecimal format.")
parser.add_argument("input_image", help="Path to the input image file.")
parser.add_argument("output_name", help="Name for the output .coe file (without extension).")

args = parser.parse_args()

# Get input and output paths
input_image_path = args.input_image
output_name = args.output_name

# Check if the input image exists
if not os.path.isfile(input_image_path):
    print(f"Error: File '{input_image_path}' does not exist.")
    exit(1)

# Process the image
try:
    # Open the image
    img = Image.open(input_image_path)

    # Remove alpha channel if it exists
    if img.mode == 'RGBA':  # If image has an alpha channel
        img = img.convert('RGB')  # Convert to RGB (remove alpha)

    # Convert image to numpy array
    img_arr = np.array(img)

    # Flatten the image array to 1D
    d1 = img_arr.flatten()

    # Determine the output file path in the same folder as the input image
    output_path = os.path.join(os.path.dirname(input_image_path), f"{output_name}.coe")

    # Write the .coe file
    with open(output_path, "w") as file:
        file.write("memory_initialization_radix=16;\n")
        file.write("memory_initialization_vector=")
        pixel_count = 0  # Initialize pixel count
        for x in range(0, len(d1), 3):  # Iterate through the list in steps of 3 (R, G, B)
            if x + 2 < len(d1):
                # Combine R, G, and B into a single 24-bit hexadecimal value
                rgb_value = (d1[x] << 16) | (d1[x + 1] << 8) | d1[x + 2]
                hex_value = format(rgb_value, '06X')  # Format as a 6-character hex value
                file.write(hex_value)
                pixel_count += 1
                if x + 3 < len(d1):  # Add a space if not the last value
                    file.write(" ")
        file.write(";")  # End the .coe file content
    print(f"Conversion complete. File saved at: {output_path}")
    print("Total No. of Pixels is: ", pixel_count)

except Exception as e:
    print(f"Error: {e}")
    exit(1)