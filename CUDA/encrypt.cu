// Compile: nvcc encrypt.cu -lnvidia-ml -o encrypt -diag-suppress 550
// Usage: ./encrypt input.png output
//*****************************************************************************************
//***************IMAGE ENCRYPTION CODE*****************************************************
//*****************************************************************************************


#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <chrono>
#include <nvml.h>


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
	unsigned char key = 0xaa;

    // Allocate GPU memory
    unsigned char *d_r, *d_g, *d_b;
    cudaMalloc((void**)&d_r, size);
    cudaMalloc((void**)&d_g, size);
    cudaMalloc((void**)&d_b, size);

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
    encrypt<<<blocks, threadsPerBlock>>>(d_r, d_g, d_b, size, key);
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
    
    nvmlShutdown();
    return 0;
}
