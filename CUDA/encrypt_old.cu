// Compile: nvcc encrypt.cu -o encrypt -diag-suppress 550
// Usage: ./encrypt input.png output
//*****************************************************************************************
//***************IMAGE ENCRYPTION CODE*****************************************************
//*****************************************************************************************


#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>

// Constant memory for S-Box
__constant__ unsigned char sboxData[16] = {
    0xc, 0x5, 0x6, 0xb, 0x9, 0x0, 0xa, 0xd,
    0x3, 0xe, 0xf, 0x8, 0x4, 0x7, 0x1, 0x2
};

// Encryption function for a single byte on GPU
__device__ unsigned char encrypt_byte(unsigned char pt, unsigned char key) {
    const unsigned char iv1 = 0xa, iv2 = 0xb;

    unsigned char p1 = pt & 0x0F;
    unsigned char p2 = (pt >> 4) & 0x0F;
    unsigned char k1 = key & 0x0F;
    unsigned char k2 = (key >> 4) & 0x0F;

    unsigned char sl1 = sboxData[p1 & 0x0F];
    unsigned char xl1 = k1 ^ sl1;
    unsigned char xl2 = iv1 ^ xl1 ^ p2;
    unsigned char sl2 = sboxData[xl2 & 0x0F];
    unsigned char xl3 = k2 ^ sl2;

    unsigned char sr1 = sboxData[p2 & 0x0F];
    unsigned char xr1 = k2 ^ sr1;
    unsigned char xr2 = iv1 ^ xr1 ^ iv2;
    unsigned char sr2 = sboxData[xr2 & 0x0F];
    unsigned char xr3 = k1 ^ sr2;

    return (xl3 << 4) | xr3;
}

// Simple kernel: invert RGB values. NOTE: This is a dummy kernel. Remove this kernel and create encryption kernels!
__global__ void encrypt(unsigned char *d_r, unsigned char *d_g, unsigned char *d_b, int size, unsigned char key) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < size) {
        d_r[idx] = encrypt_byte(d_r[idx], key);
        d_g[idx] = encrypt_byte(d_g[idx], key);
        d_b[idx] = encrypt_byte(d_b[idx], key);
    }
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage: %s <input_image> <output_prefix>\n", argv[0]);
        return -1;
    }

    int width, height, channels;
    unsigned char *img = stbi_load(argv[1], &width, &height, &channels, 3);
    if (!img) {
        printf("Error loading image %s\n", argv[1]);
        return -1;
    }

    int size = width * height;
    // Allocate CPU memory
    unsigned char *h_r = (unsigned char*)malloc(size);
    unsigned char *h_g = (unsigned char*)malloc(size);
    unsigned char *h_b = (unsigned char*)malloc(size);

    // Split into R, G, B arrays
    for (int i = 0; i < size; i++) {
        h_r[i] = img[3 * i + 0];
        h_g[i] = img[3 * i + 1];
        h_b[i] = img[3 * i + 2];
    }
    stbi_image_free(img);

	// Define the KEY for encryption (from KEY Generation Algorithm)
	unsigned char key1 = 0x11;
	unsigned char key2 = 0x22;
	unsigned char key3 = 0x33;
	unsigned char key4 = 0x44;
	unsigned char key5 = 0x55;
	unsigned char key6 = 0x66;
	unsigned char key7 = 0x77;
	unsigned char key8 = 0x88;
	unsigned char key9 = 0x99;
	unsigned char key10 = 0xaa;
	unsigned char key11 = 0xbb;

    // Allocate GPU memory
    unsigned char *d_r, *d_g, *d_b;
    cudaMalloc((void**)&d_r, size);
    cudaMalloc((void**)&d_g, size);
    cudaMalloc((void**)&d_b, size);

    // Copy from host to device
    cudaMemcpy(d_r, h_r, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_g, h_g, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, size, cudaMemcpyHostToDevice);

    // Launch kernel
    int threadsPerBlock = 512;
    int blocks = (size + threadsPerBlock - 1) / threadsPerBlock;
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key1);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key2);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key3);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key4);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key5);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key6);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key7);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key8);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key9);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key10);
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key11);
    cudaDeviceSynchronize();

    // Copy back from device to host
    cudaMemcpy(h_r, d_r, size, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_g, d_g, size, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_b, d_b, size, cudaMemcpyDeviceToHost);


    // Write HEX file (ASCII RRGGBB)
    char hexFile[256];
    snprintf(hexFile, sizeof(hexFile), "%s.hex", argv[2]);
    FILE *fhex = fopen(hexFile, "w");
    for (int i = 0; i < size; i++) {
        fprintf(fhex, "%02X%02X%02X\n", h_r[i], h_g[i], h_b[i]);
    }
    fclose(fhex);

    // Free
    cudaFree(d_r); 
    cudaFree(d_g); 
    cudaFree(d_b);
    
    free(h_r); 
    free(h_g); 
    free(h_b);

    printf("Done! Output written to %s\n", hexFile);
    return 0;
}
