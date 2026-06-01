// Compile: nvcc decrypt.cu -o decrypt -diag-suppress 550
// Usage: ./decrypt encrypted.hex <image_width> <image_height> decrypted.png
//*****************************************************************************************
//***************IMAGE DECRYPTION CODE*****************************************************
//*****************************************************************************************


#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>

// Simple kernel: invert RGB values. NOTE: This is a dummy kernel. Remove this kernel and create decryption kernels!
__global__ void view(unsigned char *d_r, unsigned char *d_g, unsigned char *d_b, int size) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < size) {
        d_r[idx] = d_r[idx];
        d_g[idx] = d_g[idx];
        d_b[idx] = d_b[idx];
    }
}

// Helper to convert hex string to byte
unsigned char hex2byte(const char *hex) {
    unsigned char byte = 0;
    for (int i = 0; i < 2; i++) {
        char c = hex[i];
        byte <<= 4;
        if (c >= '0' && c <= '9') byte |= (c - '0');
        else if (c >= 'A' && c <= 'F') byte |= (c - 'A' + 10);
        else if (c >= 'a' && c <= 'f') byte |= (c - 'a' + 10);
    }
    return byte;
}

int main(int argc, char *argv[]) {
    if (argc < 4) {
        printf("Usage: %s input.hex width height output.png\n", argv[0]);
        return -1;
    }

    const char *hexFilePath = argv[1];
    int width = atoi(argv[2]);
    int height = atoi(argv[3]);
    int size = width * height;

    // Allocate CPU memory
    unsigned char *h_r = (unsigned char*)malloc(size);
    unsigned char *h_g = (unsigned char*)malloc(size);
    unsigned char *h_b = (unsigned char*)malloc(size);

    // Open hex file
    FILE *fhex = fopen(hexFilePath, "r");
    if (!fhex) {
        printf("Error opening file %s\n", hexFilePath);
        return -1;
    }

    // Read each line as RRGGBB
    char line[16];
    int idx = 0;
    while (fgets(line, sizeof(line), fhex) && idx < size) {
        if (strlen(line) < 6) continue; // skip invalid lines
        h_r[idx] = hex2byte(line);
        h_g[idx] = hex2byte(line + 2);
        h_b[idx] = hex2byte(line + 4);
        idx++;
    }
    fclose(fhex);

    if (idx != size) {
        printf("Warning: hex file contains %d pixels, expected %d\n", idx, size);
    }

    // Allocate GPU memory
    unsigned char *d_r, *d_g, *d_b;
    cudaMalloc(&d_r, size);
    cudaMalloc(&d_g, size);
    cudaMalloc(&d_b, size);

    // Copy from host to device
    cudaMemcpy(d_r, h_r, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_g, h_g, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, size, cudaMemcpyHostToDevice);

    // Launch kernel
    int threadsPerBlock = 512;
    int blocks = (size + threadsPerBlock - 1) / threadsPerBlock;
    view<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size);
    cudaDeviceSynchronize();

    // Copy back from device to host
    cudaMemcpy(h_r, d_r, size, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_g, d_g, size, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_b, d_b, size, cudaMemcpyDeviceToHost);

    // Merge into one RGB image array
    unsigned char *img = (unsigned char*)malloc(size * 3);
    for (int i = 0; i < size; i++) {
        img[3*i + 0] = h_r[i];
        img[3*i + 1] = h_g[i];
        img[3*i + 2] = h_b[i];
    }

    // Save image
    stbi_write_png(argv[4], width, height, 3, img, width * 3);

    // Free
    free(h_r); 
    free(h_g); 
    free(h_b); 
    free(img);
    
    cudaFree(d_r); 
    cudaFree(d_g); 
    cudaFree(d_b);

    printf("Done! Image written to %s\n", argv[4]);
    return 0;
}
