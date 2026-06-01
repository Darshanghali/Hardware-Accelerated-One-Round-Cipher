// Compile: nvcc cudac decrypt.cu -lnvidia-ml -o decrypt -diag-suppress 550
// Usage: ./decrypt encrypted.hex <image_width> <image_height> decrypted.png
//*****************************************************************************************
//***************IMAGE DECRYPTION CODE*****************************************************
//*****************************************************************************************


#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <chrono>
#include <nvml.h>

// Constant memory for Inverse S-Box
__constant__ unsigned char invSboxData[16] = {
    0x5, 0xe, 0xf, 0x8, 0xc, 0x1, 0x2, 0xd,
    0xb, 0x4, 0x6, 0x3, 0x0, 0x7, 0x9, 0xa
};

// Decryption function for a single byte on GPU
__device__ unsigned char decrypt_byte(unsigned char ct, unsigned char key) {
    const unsigned char iv1 = 0xa, iv2 = 0xb;

    unsigned char c1 = ct & 0x0F;
    unsigned char c2 = (ct >> 4) & 0x0F;
    unsigned char k1 = key & 0x0F;
    unsigned char k2 = (key >> 4) & 0x0F;

	unsigned char xl1 = c1 ^ k1;
    unsigned char sl1 = invSboxData[xl1 & 0x0F];
    unsigned char xl2 = iv1 ^ iv2 ^ sl1;
    unsigned char xl3 = xl2 ^ k2;
    unsigned char p1 = invSboxData[xl3 & 0x0F];
    
    unsigned char xr1 = c2 ^ k2;
    unsigned char sr1 = invSboxData[xr1 & 0x0F];
    unsigned char xr2 = iv1 ^ sr1 ^ p1;
    unsigned char xr3 = xr2 ^ k1;
    unsigned char p2 = invSboxData[xr3 & 0x0F];

    return (p1 << 4) | p2;
}

// Simple kernel: invert RGB values. NOTE: This is a dummy kernel. Remove this kernel and create decryption kernels!
__global__ void decrypt(unsigned char *d_r, unsigned char *d_g, unsigned char *d_b, int size, unsigned char key) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < size) {
        d_r[idx] = decrypt_byte(d_r[idx], key);
        d_g[idx] = decrypt_byte(d_g[idx], key);
        d_b[idx] = decrypt_byte(d_b[idx], key);
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

    // Define the KEY for encryption (from KEY Generation Algorithm)
   	unsigned char key = 0xaa;
    

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

    // -----------------------------------------------------------
    // GPU DEVICE INFORMATION
    // -----------------------------------------------------------
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);

    printf("\n===== GPU INFORMATION =====\n");
    printf("Device Name           : %s\n", prop.name);
    printf("Compute Capability    : %d.%d\n", prop.major, prop.minor);
    printf("Total Global Memory   : %zu bytes\n", prop.totalGlobalMem);
    printf("Shared Mem Per Block  : %zu bytes\n", prop.sharedMemPerBlock);
    printf("Registers Per Block   : %d\n", prop.regsPerBlock);
    printf("Warp Size             : %d\n", prop.warpSize);
    printf("Max Threads Per Block : %d\n", prop.maxThreadsPerBlock);
    printf("SM Count              : %d\n", prop.multiProcessorCount);
    printf("Clock Rate            : %d kHz\n", prop.clockRate);
    printf("Memory Clock Rate     : %d kHz\n", prop.memoryClockRate);
    printf("Memory Bus Width      : %d bits\n", prop.memoryBusWidth);
    printf("L2 Cache Size         : %d bytes\n", prop.l2CacheSize);
    printf("===========================\n\n");
	
	nvmlInit();
	nvmlDevice_t device;
	nvmlDeviceGetHandleByIndex(0, &device);
	
	printf("\n===== LIVE GPU MONITORING =====\n");
	
	nvmlUtilization_t util;
	unsigned int temp = 0;
	unsigned int power = 0;

	nvmlDeviceGetUtilizationRates(device, &util);
	nvmlDeviceGetTemperature(device, NVML_TEMPERATURE_GPU, &temp);
	nvmlDeviceGetPowerUsage(device, &power);
	
	printf("Before Kernel: GPU Util=%d%%  Mem Util=%d%%  Temp=%dC  Power=%.2fW\n", util.gpu, util.memory, temp, power/1000.0);

    // -----------------------------------------------------------
    // START TOTAL GPU TIMER
    // -----------------------------------------------------------
    cudaEvent_t totalStart, totalStop;
    cudaEventCreate(&totalStart);
    cudaEventCreate(&totalStop);

    cudaEventRecord(totalStart);

    // Launch kernel
    int threadsPerBlock = 512;
    int blocks = (size + threadsPerBlock - 1) / threadsPerBlock;
    decrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key);
    cudaDeviceSynchronize();

	// -----------------------------------------------------------
    // STOP TOTAL GPU TIMER
    // -----------------------------------------------------------
    cudaEventRecord(totalStop);
    cudaEventSynchronize(totalStop);

    float totalMs = 0;
    cudaEventElapsedTime(&totalMs, totalStart, totalStop);

    printf("\nTotal GPU Kernel Execution Time = %.3f ms\n\n", totalMs);

    cudaEventDestroy(totalStart);
    cudaEventDestroy(totalStop);

	nvmlDeviceGetUtilizationRates(device, &util);
	nvmlDeviceGetTemperature(device, NVML_TEMPERATURE_GPU, &temp);
	nvmlDeviceGetPowerUsage(device, &power);
	
	printf("After Kernel: GPU Util=%d%%  Mem Util=%d%%  Temp=%dC  Power=%.2fW\n", util.gpu, util.memory, temp, power/1000.0);
	
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
    
    nvmlShutdown();
    return 0;
}
