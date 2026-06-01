#!/usr/bin/env python3
import sys, math, numpy as np
from collections import Counter

##############################################
# HELPER FUNCTIONS
##############################################

def read_bits_from_hex_file(fname):
    with open(fname, "r") as f:
        txt = f.read().strip().replace(" ", "").replace("\n", "")
    data = bytes.fromhex(txt)
    bits = ''.join(f"{b:08b}" for b in data)
    return bits


def erfc(x):
    return math.erfc(x)


##############################################
# 1. MONOBIT TEST
##############################################

def monobit_test(bits):
    n = len(bits)
    ones = bits.count('1')
    zeros = n - ones
    s = abs(ones - zeros)
    test_stat = s / math.sqrt(n)
    p = erfc(test_stat / math.sqrt(2))
    return p


##############################################
# 2. BLOCK FREQUENCY TEST
##############################################

def block_frequency_test(bits, M=128):
    n = len(bits)
    N = n // M
    if N == 0:
        return None
    s = 0
    for i in range(N):
        block = bits[i*M:(i+1)*M]
        pi = block.count('1') / M
        s += (pi - 0.5)**2
    chi2 = 4 * M * s
    p = erfc(abs(chi2 - N) / (math.sqrt(2 * N)))
    return p


##############################################
# 3. RUNS TEST
##############################################

def runs_test(bits):
    n = len(bits)
    pi = bits.count('1') / n
    if abs(pi - 0.5) >= (2 / math.sqrt(n)):
        return 0.0
    V = 1 + sum(bits[i] != bits[i-1] for i in range(1, n))
    num = abs(V - 2*n*pi*(1-pi))
    den = 2*math.sqrt(2*n)*pi*(1-pi)
    p = erfc(num/den)
    return p


##############################################
# 4. LONGEST RUN OF ONES IN BLOCKS
##############################################

def longest_run_test(bits, M=128):
    n = len(bits)
    N = n // M
    longest = []
    for i in range(N):
        block = bits[i*M:(i+1)*M]
        max_r = 0
        curr = 0
        for b in block:
            if b == '1':
                curr += 1
                max_r = max(max_r, curr)
            else:
                curr = 0
        longest.append(max_r)
    # Compare with expected distribution via approximations
    mean_longest = np.mean(longest)
    var = np.var(longest)
    # z-score:
    z = (mean_longest - 0.7 * math.log(M)) / math.sqrt(var+1e-9)
    p = erfc(abs(z)/math.sqrt(2))
    return p


##############################################
# 5. MATRIX RANK TEST (32x32)
##############################################

def matrix_rank_test(bits, M=32, Q=32):
    block_size = M * Q
    N = len(bits) // block_size
    if N == 0:
        return None

    def gf2_rank(matrix):
        A = matrix.copy()
        rows, cols = A.shape
        rank = 0
        r = 0
        for c in range(cols):
            pivot = None
            for rr in range(r, rows):
                if A[rr, c] == 1:
                    pivot = rr
                    break
            if pivot is None:
                continue
            if pivot != r:
                A[[r, pivot]] = A[[pivot, r]]
            for rr in range(r+1, rows):
                if A[rr, c] == 1:
                    A[rr] ^= A[r]
            r += 1
            rank += 1
        return rank

    ranks = []
    for i in range(N):
        block = bits[i*block_size:(i+1)*block_size]
        mat = np.array([list(map(int, block[j*Q:(j+1)*Q])) for j in range(M)], dtype=np.uint8)
        ranks.append(gf2_rank(mat))

    full = ranks.count(M)
    prob_full = 1.0
    for i in range(M):
        prob_full *= (1 - 2**(i-M))

    expected_full = prob_full * N
    chi2 = (full - expected_full)**2 / (expected_full + 1e-9)
    p = math.exp(-chi2 / 2)
    return p


##############################################
# 6. SPECTRAL (DFT) TEST
##############################################

def spectral_test(bits, max_len=200000):
    x = np.array([1 if b == '1' else -1 for b in bits[:max_len]])
    S = np.fft.fft(x)
    mag = np.abs(S[:len(x)//2])
    T = math.sqrt(math.log(1/0.05) * len(mag))
    peaks = np.sum(mag > T)
    expected = 0.95 * len(mag)
    z = (peaks - expected) / math.sqrt(len(mag)*0.95*0.05)
    p = erfc(abs(z)/math.sqrt(2))
    return p


##############################################
# 7. APPROXIMATE ENTROPY TEST
##############################################

def approximate_entropy(bits, m=10):
    n = len(bits)
    def _phi(m):
        counts = Counter(bits[i:i+m] for i in range(n-m+1))
        total = n-m+1
        return sum((v/total)*math.log(v/total) for v in counts.values())
    ApEn = _phi(m) - _phi(m+1)
    chi2 = 2*n*(math.log(2) - ApEn)
    p = math.exp(-chi2/2)
    return p


##############################################
# 8. CUMULATIVE SUMS (CUSUM)
##############################################

def cusum_test(bits):
    x = np.array([1 if b=='1' else -1 for b in bits])
    S = np.cumsum(x)
    z = np.max(np.abs(S))
    p = erfc(z / math.sqrt(len(bits)))
    return p


##############################################
# MAIN EXECUTION
##############################################

def run_all_tests(bits):
    tests = {}

    tests["Monobit"] = monobit_test(bits)
    tests["Block Frequency"] = block_frequency_test(bits)
    tests["Runs"] = runs_test(bits)
    tests["Longest Run"] = longest_run_test(bits)
    tests["Matrix Rank"] = matrix_rank_test(bits)
    tests["Spectral-DFT"] = spectral_test(bits)
    tests["Approx Entropy"] = approximate_entropy(bits)
    tests["CUSUM"] = cusum_test(bits)

    return tests


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 nist_test_suite.py file.hex")
        return

    fname = sys.argv[1]
    bits = read_bits_from_hex_file(fname)

    print("\nRunning NIST Statistical Tests...\n")
    results = run_all_tests(bits)

    print("=============== RESULTS ===============")
    for test, p in results.items():
        if p is None:
            print(f"{test:20s}:  NOT RUN")
        else:
            print(f"{test:20s}:  p = {p:.6g}   -->  {'PASS' if p>=0.01 else 'FAIL'}")
    print("=======================================\n")

    # Save to CSV
    with open("nist_results.csv", "w") as f:
        f.write("Test,p_value,Result\n")
        for test, p in results.items():
            if p is None:
                f.write(f"{test},,\n")
            else:
                f.write(f"{test},{p},{'PASS' if p>=0.01 else 'FAIL'}\n")

    print("Results saved to nist_results.csv")


if __name__ == "__main__":
    main()
