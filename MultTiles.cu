#include <chrono>
#include <ctime>
#include <cuda.h>
#include <fstream>
#include <iostream>
#include <stdio.h>
#include <time.h>
using namespace std;

#define TILE_WIDTH 16

__global__ void matrixMultiply(float *A, float *B, float *C, int numARows,
                               int numAColumns, int numBRows, int numBColumns,
                               int numCRows, int numCColumns) {
  __shared__ float ds_M[TILE_WIDTH][TILE_WIDTH];
  __shared__ float ds_N[TILE_WIDTH][TILE_WIDTH];

  int bx = blockIdx.x;
  int by = blockIdx.y;
  int tx = threadIdx.x;
  int ty = threadIdx.y;

  int Row = by * TILE_WIDTH + ty;
  int Col = bx * TILE_WIDTH + tx;
  float Pvalue = 0;
  // ciclo sobre las matrices "shared" M y N  para calcular el
  // elemento P
  for (int m = 0; m < (numAColumns - 1) / TILE_WIDTH + 1; ++m) {
    // Se verifica que tanto como tx como ty, no excedan el tamaño de la
    // matrices, y si lo llegaran a hacer por el tamaño del grid, estos se
    // asignaran como 0
    if (Row < numARows && ((m * TILE_WIDTH) + tx) < numAColumns) {
      ds_M[ty][tx] = A[Row * numAColumns + m * TILE_WIDTH + tx];

    } else {
      ds_M[ty][tx] = 0;
    }
    if ((Col < numBColumns) && ((m * TILE_WIDTH) + ty) < numBRows) {
      ds_N[ty][tx] = B[(m * TILE_WIDTH + ty) * numBColumns + Col];

    } else {
      ds_N[ty][tx] = 0.0;
    }
    __syncthreads();
    for (int k = 0; k < TILE_WIDTH; ++k)
      Pvalue += ds_M[ty][k] * ds_N[k][tx];
    __syncthreads();
  }
  // Solo se guardaran si hilos corresponden a una posicion valida para la
  // matriz resultante
  if (Row < numCRows && Col < numCColumns) {
    C[Row * numCColumns + Col] = Pvalue;
  }
}
void matMultiplyOnHost(float *A, float *B, float *C, int numARows,
                       int numAColumns, int numBRows, int numBColumns,
                       int numCRows, int numCColumns) {
  for (int i = 0; i < numARows; i++) {
    for (int j = 0; j < numBColumns; j++) {
      float result = 0.0;
      for (int k = 0; k < numAColumns; k++) {
        result += A[i * numAColumns + k] * B[k * numBColumns + j];
      }
      C[i * numBColumns + j] = result;
    }
  }
}
void Check(float *m_h, float *m_d, int numCRows, int numCColumns) {
  for (int i = 0; i < numCRows * numCColumns; i++) {
    if (m_h[i] != m_d[i]) {
      cout << "Iqual: False" << endl;
      break;
    }
  }
  cout << "Iqual: True" << endl;
}

int main() {

  float *hostA; // The A matrix
  float *hostB; // The B matrix
  float *hostC; // The output C matrix
  float *hostResultC;
  float *deviceA = NULL;
  float *deviceB = NULL;
  float *deviceC = NULL;
  int numArows = 5000;    // number of rows in the matrix A
  int numAColumns = 2500; // number of columns in the matrix A
  int numBrows = 2500;    // number of rows in the matrix B
  int numBColumns = 5000; // number of columns in the matrix B
  int numCrows;
  int numCColumns;

  if (numAColumns == numBrows) {

    numCrows = numArows;
    numCColumns = numBColumns;

    float sizeA = sizeof(float) * numArows * numAColumns;
    float sizeB = sizeof(float) * numBrows * numBColumns;
    float sizeC = sizeof(float) * numCrows * numCColumns;

    // Memoria en host
    // Reservo memoria en el host, la cantidad de columnas x filas x el tamaño
    // de cada dato.
    hostA = (float *)malloc(sizeA);
    hostB = (float *)malloc(sizeB);
    hostC = (float *)malloc(sizeC);
    hostResultC = (float *)malloc(sizeC);

    // Llenamos matrices
    for (int i = 0; i < numArows * numAColumns; i++) {
      hostA[i] = 3;
    }

    for (int i = 0; i < numBrows * numBColumns; i++) {
      hostB[i] = 2;
    }

    // Memoria en device
    std::chrono::time_point<std::chrono::system_clock> start, end;
    std::chrono::duration<double> elapsed_seconds;
    start = std::chrono::system_clock::now();
    // Resevamos memoria en el device, del mismo tamaño que las anteriores
    // matrices.
    cudaMalloc((void **)&deviceA, sizeA);
    cudaMalloc((void **)&deviceB, sizeB);
    cudaMalloc((void **)&deviceC, sizeC);
    end = std::chrono::system_clock::now();
    elapsed_seconds = end - start;
    cout << "Cuda Malloc Time: " << elapsed_seconds.count() << "s\n";

    // Host to Device
    start = std::chrono::system_clock::now();
    // Pasamos la informacion que posee las matrices que estan en el host al
    // device
    cudaMemcpy(deviceA, hostA, sizeA, cudaMemcpyHostToDevice);
    cudaMemcpy(deviceB, hostB, sizeB, cudaMemcpyHostToDevice);
    end = std::chrono::system_clock::now();
    elapsed_seconds = end - start;

    cout << "Cuda Memcpy Host to Device Time: " << elapsed_seconds.count()
         << "s\n";

    start = std::chrono::system_clock::now();
    // Definimos tamaño del Grid y del bloque
    // Donde si tenemos una matriz de MxN, N sera la cantidad de columnas en el
    // grid y M la cantidad de filas en el grid..
    // El tamaño del bloque es Tile_width x Tile_width

    dim3 dimGrid((numCColumns - 1) / TILE_WIDTH + 1,
                 (numCrows - 1) / TILE_WIDTH + 1, 1);
    dim3 dimBlock(TILE_WIDTH, TILE_WIDTH, 1);
    end = std::chrono::system_clock::now();
    elapsed_seconds = end - start;
    cout << "Dims Time: " << elapsed_seconds.count() << "s\n";

    // Multiplicacion de matrices utilizando tiles en device
    start = std::chrono::system_clock::now();
    // Hago a la función donde le envío las matrices y sus respectivo datos
    matrixMultiply<<<dimGrid, dimBlock>>>(deviceA, deviceB, deviceC, numArows,
                                          numAColumns, numBrows, numBColumns,
                                          numCrows, numCColumns);
    end = std::chrono::system_clock::now();
    elapsed_seconds = end - start;
    cout << "Multplication Device Time: " << elapsed_seconds.count() << "s\n";

    // Device to Host
    start = std::chrono::system_clock::now();

    cudaMemcpy(hostC, deviceC, sizeC, cudaMemcpyDeviceToHost);
    end = std::chrono::system_clock::now();
    elapsed_seconds = end - start;
    cout << "Cuda Memcmpy Device to Host Time: " << elapsed_seconds.count()
         << "s\n";
    // Multiplication Host
    start = std::chrono::system_clock::now();

    matMultiplyOnHost(hostA, hostB, hostResultC, numArows, numAColumns,
                      numBrows, numBColumns, numCrows, numCColumns);
    end = std::chrono::system_clock::now();
    elapsed_seconds = end - start;
    cout << "Matrix Multiplication Host Time: " << elapsed_seconds.count()
         << "s\n";
    Check(hostC, hostResultC, numCrows, numCColumns);

  } else {
    cout << "Las matrices no se pueden multiplicar " << endl;
  }
  cudaFree(deviceA);
  cudaFree(deviceB);
  cudaFree(deviceC);

  free(hostA);
  free(hostB);
  free(hostC);
  return 0;
}
