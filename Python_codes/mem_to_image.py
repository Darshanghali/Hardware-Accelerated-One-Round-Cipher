import argparse
from PIL import Image

def mem_to_image(mem_file_path, image_file_path, width=320, height=240):
    # Open the .mem file and read the data
    with open(mem_file_path, 'r') as file:
        data = file.readlines()

    # Initialize an empty list for pixel data
    pixels = []

    for line in data:
        # Remove comments and whitespace
        line = line.strip()
        if not line or line.startswith("//"):  # Skip empty lines and comments
            continue
        
        # Parse the hexadecimal value
        hex_value = line.split(':')[1].strip() if ':' in line else line
        hex_value = hex_value.replace(";", "")  # Remove semicolon if present
        r = int(hex_value[0:2], 16)  # Red
        g = int(hex_value[2:4], 16)  # Green
        b = int(hex_value[4:6], 16)  # Blue
        pixels.append((r, g, b))

    # Ensure the number of pixels matches the expected image size
    if len(pixels) != width * height:
        raise ValueError(f"Invalid number of pixels: expected {width * height}, got {len(pixels)}")

    # Create an image from the pixel data
    img = Image.new('RGB', (width, height))
    img.putdata(pixels)

    # Save the image
    img.save(image_file_path)
    print(f"Image saved as {image_file_path}")

if __name__ == "__main__":
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Convert a .mem file with RGB values to an image.")
    parser.add_argument("mem_file", help="Path to the input .mem file")
    parser.add_argument("output_image", help="Path to save the output image file")
    parser.add_argument("--width", type=int, default=320, help="Width of the output image (default: 320)")
    parser.add_argument("--height", type=int, default=240, help="Height of the output image (default: 240)")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Call the conversion function
    mem_to_image(args.mem_file, args.output_image, args.width, args.height)