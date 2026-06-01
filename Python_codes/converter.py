import sys

def mem_to_hex(mem_path, hex_path):
    with open(mem_path, "r") as mem_file:
        lines = mem_file.readlines()

    clean_hex = []

    for line in lines:
        line = line.strip()

        if not line:
            continue  # skip empty lines

        # remove "0x" or "0X" if present
        if line.lower().startswith("0x"):
            line = line[2:]

        # uppercase for consistency
        clean_hex.append(line.upper())

    # write each hex value on a new line
    with open(hex_path, "w") as hex_file:
        for value in clean_hex:
            hex_file.write(value + "\n")

    print(f"Converted '{mem_path}' → '{hex_path}' (line-by-line)!")


# usage: python converter.py input.mem output.hex
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python converter.py <input.mem> <output.hex>")
        sys.exit(1)

    mem_to_hex(sys.argv[1], sys.argv[2])
