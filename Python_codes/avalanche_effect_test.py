# --- Step 1: Upload .hex files in Colab ---
from google.colab import files
uploaded = files.upload()   # ← pick your 2 files here

# --- Step 2: Avalanche code with truncation ---
import matplotlib.pyplot as plt

MAX_BYTES = 65536  # compare only first 65535 bytes

def load_hex_limited(path, max_bytes=MAX_BYTES):
    with open(path, "r") as f:
        hex_str = f.read().strip().replace(" ", "").replace("\n", "")
    hex_str = hex_str[:max_bytes * 2]   # 2 hex chars per byte
    return bytes.fromhex(hex_str)

def avalanche_from_files_plot_limited(path_ct1, path_ct2):
    c1 = load_hex_limited(path_ct1)
    c2 = load_hex_limited(path_ct2)

    flipped_bits = []
    diff_count = 0

    for i in range(len(c1)):
        xor_val = c1[i] ^ c2[i]
        for b in range(8):
            bit = (xor_val >> b) & 1
            flipped_bits.append(bit)
            diff_count += bit

    total_bits = len(flipped_bits)
    percentage = (diff_count / total_bits) * 100

    print(f"Bytes compared: {len(c1)}")
    print(f"Total bits: {total_bits}")
    print(f"Bits flipped: {diff_count}")
    print(f"Avalanche: {percentage:.2f}%")

    plt.figure(figsize=(14, 4))
    plt.bar(range(total_bits), flipped_bits)
    plt.title("Avalanche Effect Bit Flip Map (Truncated)")
    plt.xlabel("Bit Position")
    plt.ylabel("Flipped (1 = Yes, 0 = No)")
    plt.tight_layout()
    plt.show()

# --- Step 3: Run the function with the uploaded filenames ---
# Replace these filenames with EXACT names shown after upload
avalanche_from_files_plot_limited(
    "encrypted_cuda_1_round.hex",
    "encrypted_cuda_flipped_1_round.hex"
)
