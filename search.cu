#include <cstring>
#include <filesystem>
#include <iostream>
#include <vector>

#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <device_launch_parameters.h>

namespace fs = std::filesystem;

struct file {
  char *path;
};

__global__ void search_target_file(file *files, char *target_file_name) {
  int idx = blockIdx.x;
  if (files[idx].path != nullptr) {
    char *temp;
    temp = files[idx].path;
    printf("%c", temp[0]);
  }
}

int main(int argc, char **argv) {
  std::string search_target = argv[1];
  std::cout << "Your target file name : " << search_target << std::endl;

  fs::path current_path = fs::current_path();
  std::cout << "Target directory : " << current_path << std::endl;
  auto dir_iterator = fs::recursive_directory_iterator{current_path};

  std::vector<file> files;
  int file_ctr = 0;
  for (const auto &dir_entry : dir_iterator) {
    auto current_path = dir_entry.path();
    for (auto it = current_path.begin(); it != current_path.end(); ++it) {
      std::string selected_path = it->string();
      file selected_file;
      selected_file.path = (char *)malloc(strlen(selected_path.data()) + 1);
      strcpy(selected_file.path, selected_path.data());
      files.push_back(selected_file);
      file_ctr++;
    }
  }

  file *files_ptr = files.data();
  size_t files_size = sizeof(*files_ptr) * files.size();
  file *device_files = (file *)malloc(files_size);
  cudaMalloc(&device_files, files_size);
  cudaMemcpy(device_files, files_ptr, files_size, cudaMemcpyHostToDevice);

  char *target = search_target.data();
  size_t target_size = sizeof(target);
  char *device_target = (char *)malloc(target_size);
  cudaMalloc(&device_target, target_size);
  cudaMemcpy(device_target, target, target_size, cudaMemcpyHostToDevice);

  search_target_file<<<1000, 1>>>(device_files, device_target);
  cudaDeviceSynchronize();
  cudaError_t error = cudaPeekAtLastError();
  if (error != cudaSuccess) {
    std::cout << "Error in kernel code : " << cudaGetErrorName(error) << " -> "
              << cudaGetErrorString(error) << std::endl;
  }
  cudaFree(device_files);
  cudaFree(device_target);
  return 0;
}
