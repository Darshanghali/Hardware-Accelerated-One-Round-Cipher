# coe_to_mem.py
# Converts a Xilinx .coe file (like lena1.coe) into a plain .mem file usable by Verilog ($readmemh)

input_file = "lena1.coe"   # your input file
output_file = "lena1.mem"  # output .mem file

found_vector = False
lines_written = 0

with open(input_file, "r") as fin, open(output_file, "w") as fout:
    for line in fin:
        stripped = line.strip()

        if not stripped:
            continue

        # detect start of data section
        if "memory_initialization_vector" in stripped.lower():
            found_vector = True
            # remove everything before '=' (in same line)
            if "=" in stripped:
                stripped = stripped.split("=")[-1].strip()
            # if numbers follow on same line, process them
            if stripped:
                data_values = stripped.replace(",", " ").replace(";", "").split()
                for val in data_values:
                    fout.write(val + "\n")
                    lines_written += 1
            continue

        if not found_vector:
            continue

        # stop if semicolon-only line found
        if stripped == ";":
            break

        # split values by space/comma/semicolon
        data_values = stripped.replace(",", " ").replace(";", "").split()
        for val in data_values:
            fout.write(val + "\n")
            lines_written += 1

print(f"✅ Conversion complete. {lines_written} entries written to '{output_file}'.")
