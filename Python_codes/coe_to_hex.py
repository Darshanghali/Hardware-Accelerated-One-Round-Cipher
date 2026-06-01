import sys
import re

def coe_to_hex(coe_path, hex_path):
    with open(coe_path, 'r') as f:
        text = f.read()

    # Extract radix
    radix_match = re.search(r"memory_initialization_radix\s*=\s*(\d+)\s*;", text, re.I)
    if not radix_match:
        print("Error: Could not find radix in COE file.")
        return

    radix = int(radix_match.group(1))

    # Extract vector data
    vec_match = re.search(r"memory_initialization_vector\s*=\s*(.*?);", text, re.I | re.S)
    if not vec_match:
        print("Error: Could not find memory vector.")
        return

    vec_raw = vec_match.group(1)

    # Split values (removes commas, spaces, line breaks)
    values = re.split(r"[, \n\r\t]+", vec_raw.strip())
    values = [v for v in values if v != ""]

    # Convert each value to hex (if radix isn't already 16)
    hex_vals = []
    for v in values:
        if radix == 16:
            hex_vals.append(v.lower())
        else:
            hex_vals.append(format(int(v, radix), "x"))

    # Write hex output (one value per line)
    with open(hex_path, 'w') as out:
        for h in hex_vals:
            out.write(h + "\n")

    print(f"Conversion successful! Saved to {hex_path}")

# Command-line usage
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python coe_to_hex.py input.coe output.hex")
    else:
        coe_to_hex(sys.argv[1], sys.argv[2])
