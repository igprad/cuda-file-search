#include <cstring>
#include <filesystem>
#include <iostream>
#include <vector>

#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <device_launch_parameters.h>

/*
 * There's still an issue when assign / copy values from host to device for char
 * **
 * TODO: : figure out the workaround.
 */

namespace fs = std::filesystem;

__device__ int validate_file(char *file, char *target) {
  printf("%c\n", file[0]);
  return 0;
}

__global__ void search_target_file(char **files, char *target_file_name,
                                   int limit) {
  int idx = blockIdx.x;
  char *path = files[idx];
  if (idx < limit) {
    validate_file(path, target_file_name);
  }
}

int main(int argc, char **argv) {
  std::string search_target = argv[1];
  std::cout << "Your target file name : " << search_target << std::endl;

  fs::path current_path = fs::current_path();
  std::cout << "Target directory : " << current_path << std::endl;
  auto dir_iterator = fs::recursive_directory_iterator{current_path};

  std::vector<char *> files;
  int files_char_ctr = 0;
  for (const auto &dir_entry : dir_iterator) {
    auto current_path = dir_entry.path();
    for (auto it = current_path.begin(); it != current_path.end(); ++it) {
      std::string selected_path = it->string();
      files.push_back(selected_path.data());
      files_char_ctr += selected_path.size();
    }
  }

  // Create and assign device pointer for target search file
  char *target = search_target.data();
  size_t target_size = sizeof(target);
  char *device_target = (char *)malloc(target_size);
  cudaMalloc(&device_target, target_size);
  cudaMemcpy(device_target, target, target_size, cudaMemcpyHostToDevice);

  // Create and assign device pointer for path files
  char **device_files_ptr =
      (char **)malloc(sizeof(char) * files.size() * files_char_ctr);
  cudaMalloc(&device_files_ptr, sizeof(char) * files.size() * files_char_ctr);
  cudaMemcpy(device_files_ptr, files.data(),
             sizeof(char) * files.size() * files_char_ctr,
             cudaMemcpyHostToDevice);
  for (int i = 0; i < files.size(); i++) {
    size_t size = sizeof(char) * strlen(files[i]);
    // cudaMalloc(&device_files_ptr[i], size);
    // cudaMemcpy(device_files_ptr[i], files[i], size, cudaMemcpyHostToDevice);
  }

  // Execute device kernel to search the file
  search_target_file<<<1000, 1>>>(device_files_ptr, device_target,
                                  files.size());
  cudaDeviceSynchronize();
  cudaError_t error = cudaPeekAtLastError();
  if (error != cudaSuccess) {
    std::cout << "Error in kernel code : " << cudaGetErrorName(error) << " -> "
              << cudaGetErrorString(error) << std::endl;
  }
  cudaFree(device_target);
  return 0;
}
