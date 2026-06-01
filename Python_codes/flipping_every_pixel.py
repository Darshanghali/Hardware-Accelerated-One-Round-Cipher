import sys, os

def flip_one_bit_each_line(input_file, output_file, bit_index):
    """
    Flips the SAME bit in EVERY line of a .mem file.
    Each line contains a 24-bit hex value (RRGGBB).
    bit_index: 0 to 23
    """

    if not os.path.exists(input_file):
        print(f"ERROR: Input file not found: {input_file}")
        return

    # Read all pixel lines
    with open(input_file, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    new_lines = []

    for line in lines:
        value = int(line, 16)
        flipped = value ^ (1 << bit_index)
        new_lines.append(f"{flipped:06X}")

    # Save output file
    with open(output_file, "w") as f:
        for line in new_lines:
            f.write(line + "\n")

    print("\n✨ SUCCESS!")
    print(f"Flipped bit {bit_index} in ALL {len(lines)} pixels")
    print(f"Output saved to: {os.path.abspath(output_file)}\n")


# ---- CMD Usage ----
# python flipall.py input.mem output.mem <bit_index>
if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python flipall.py <input.mem> <output.mem> <bit_index>")
        sys.exit(1)

    flip_one_bit_each_line(
        sys.argv[1],
        sys.argv[2],
        int(sys.argv[3])
    )
