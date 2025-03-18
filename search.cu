#include <cstring>
#include <filesystem>
#include <iostream>

#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <device_launch_parameters.h>

namespace fs = std::filesystem;

/*
 * TODO:
 * 1) Since device kernel cannot handle pointer of pointer (afaik) will try
 *  a) using struct, if not works [ ] -> result : TBD
 *  b) using Cuda Thrust Vector [ ] -> result : TBD
 */

__device__ int validate_path_target(char *path, char *target) { return 0; }

__global__ void search_target_file(char *paths, char *target_file_name) {
  int offset_x = threadIdx.x;
  int offset_y = blockIdx.x;
  int idx = offset_x + offset_y * offset_x;
  if (paths[idx] != '\0')
    printf("Current path element -> %c\n", paths[idx]);
}

int main(int argc, char **argv) {
  std::string search_target = argv[1];
  std::cout << "Your target file name : " << search_target << std::endl;

  fs::path current_path = fs::current_path();
  std::cout << "Target directory : " << current_path << std::endl;
  auto dir_iterator = fs::recursive_directory_iterator{current_path};

  std::string all_paths;
  for (const auto &dir_entry : dir_iterator) {
    auto current_path = dir_entry.path();
    for (auto it = current_path.begin(); it != current_path.end(); ++it) {
      all_paths.append("&").append(it->string());
    }
  }
  char *all_paths_chr_ptr = all_paths.data();
  size_t path_size = sizeof(char) * strlen(all_paths_chr_ptr);
  char *device_paths = (char *)malloc(path_size);
  cudaMalloc(&device_paths, path_size);
  cudaMemcpy(device_paths, all_paths_chr_ptr, path_size,
             cudaMemcpyHostToDevice);

  char *target = search_target.data();
  size_t target_size = sizeof(char) * strlen(target);
  char *device_target = (char *)malloc(target_size);
  cudaMalloc(&device_target, target_size);
  cudaMemcpy(device_target, target, target_size, cudaMemcpyHostToDevice);

  search_target_file<<<1000, 1000>>>(device_paths, device_target);
  cudaDeviceSynchronize();

  cudaError_t error = cudaPeekAtLastError();
  if (error != cudaSuccess) {
    std::cout << "Error in kernel code : " << cudaGetErrorName(error) << " -> "
              << cudaGetErrorString(error) << std::endl;
  }

  cudaFree(device_paths);
  cudaFree(device_target);
  return 0;
}
