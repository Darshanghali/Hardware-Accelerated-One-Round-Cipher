import math
from collections import Counter
from datetime import datetime

def shannon_entropy_from_hex(hex_file):
    with open(hex_file, "r") as f:
        hex_data = f.read().replace(" ", "").replace("\n", "")
    byte_data = bytes.fromhex(hex_data)

    freq = Counter(byte_data)
    total = len(byte_data)

    entropy = -sum((count/total) * math.log2(count/total)
                   for count in freq.values())
    return entropy


if __name__ == "__main__":

    hex_file = "encrypted.hex"   # 🔁 change file name if needed

    entropy = shannon_entropy_from_hex(hex_file)
    ratio = entropy / 8.0

    print("\n================================================")
    print("        SHANNON ENTROPY ANALYSIS REPORT")
    print("================================================")
    print(f"Test Status        : SUCCESS ✅")
    print(f"Analysis Timestamp : {datetime.now()}")
    print(f"\nShannon Entropy    : {entropy:.6f} bits/byte")
    print(f"Entropy Ratio      : {ratio:.6f}")
    
    if ratio >= 0.95:
        print("\nInterpretation     : High randomness achieved ✅")
    elif ratio >= 0.90:
        print("\nInterpretation     : Moderate randomness achieved ⚠️")
    else:
        print("\nInterpretation     : Low randomness detected ❌")

    print("================================================\n")
