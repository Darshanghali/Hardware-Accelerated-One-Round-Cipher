import argparse
from PIL import Image

def hex_to_image(hex_file_path, image_file_path, width=256, height=256):
    # Open the .hex file and read the data
    with open(hex_file_path, 'r') as file:
        data = file.readlines()

    # Initialize an empty list for pixel data
    pixels = []

    for line in data:
        # Remove comments, whitespace, and newlines
        line = line.strip()
        if not line:  # Skip empty lines
            continue
        
        # Parse the hexadecimal value (assuming each line contains one 24-bit hex value)
        hex_value = line.strip()
        # Ensure the hex value has 6 characters (24 bits)
        if len(hex_value) < 6:
            # Pad with zeros if necessary
            hex_value = hex_value.zfill(6)
        elif len(hex_value) > 6:
            # Take the last 6 characters if longer
            hex_value = hex_value[-6:]
        
        # Extract RGB components (2 hex digits per color)
        r = int(hex_value[0:2], 16)  # Red
        g = int(hex_value[2:4], 16)  # Green
        b = int(hex_value[4:6], 16)  # Blue
        pixels.append((r, g, b))

    # Check if we have enough pixels for 256x256 image
    expected_pixels = width * height  # 256 * 256 = 65536 pixels
    if len(pixels) < expected_pixels:
        print(f"Warning: Only {len(pixels)} pixels found, expected {expected_pixels}. Padding with black.")
        # Pad with black pixels
        pixels.extend([(0, 0, 0)] * (expected_pixels - len(pixels)))
    elif len(pixels) > expected_pixels:
        print(f"Warning: {len(pixels)} pixels found, expected {expected_pixels}. Truncating excess pixels.")
        # Truncate to expected size
        pixels = pixels[:expected_pixels]

    # Create an image from the pixel data
    img = Image.new('RGB', (width, height))
    img.putdata(pixels)

    # Save the image
    img.save(image_file_path)
    print(f"Image saved as {image_file_path} (Size: {width}x{height}, Pixels: {len(pixels)})")

if __name__ == "__main__":
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Convert a .hex file with RGB values to a 256x256 image.")
    parser.add_argument("hex_file", help="Path to the input .hex file")
    parser.add_argument("output_image", help="Path to save the output image file")
    parser.add_argument("--width", type=int, default=256, help="Width of the output image (default: 256)")
    parser.add_argument("--height", type=int, default=256, help="Height of the output image (default: 256)")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Call the conversion function
    hex_to_image(args.hex_file, args.output_image, args.width, args.height)