#include <algorithm>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <iterator>
#include <vector>

#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <device_launch_parameters.h>

namespace fs = std::filesystem;

__device__ void validate_path_target(char *path, char *target, bool *result) {
  // TODO: to be improved
  int limit = 100;
  for (int i = 0; i < limit; i++) {
    if (path[i] != target[i]) {
      *result = false;
    }
  }
}

// TODO: fix the implementation, still getting invalid result (might be an error
// @_@)
__global__ void search_target_file(char **paths, char *target_file_name) {
  int idx = blockIdx.x;
  char *current_path = paths[idx];
  /*
   * Notes: since this is device function, some package / library will be not
   * recognize
   * TODO: to be improved
   */
  bool found = true;
  validate_path_target(current_path, target_file_name, &found);
  if (found) {
    printf("Found.\n");
  }
}

int main(int argc, char **argv) {
  std::string search_target = argv[1];
  std::cout << "Your target file name : " << search_target << std::endl;

  fs::path current_path = fs::current_path();
  std::cout << "Target directory : " << current_path << std::endl;
  auto dir_iterator = fs::recursive_directory_iterator{current_path};

  // Collect all paths to vector
  std::vector<std::string> available_paths;
  for (const auto &dir_entry : dir_iterator) {
    auto current_path = dir_entry.path();
    for (auto iterator = current_path.begin(); iterator != current_path.end();
         ++iterator) {
      available_paths.push_back(iterator->string());
    }
  }

  std::vector<char *> cpaths;
  cpaths.reserve(available_paths.size() + 1);
  std::transform(available_paths.begin(), available_paths.end(),
                 std::back_inserter(cpaths), [](const std::string &s) {
                   char *pc = new char[s.size() + 1];
                   strcpy(pc, s.c_str());
                   return pc;
                 });
  cpaths.push_back(nullptr);
  char **cpaths_ptr = cpaths.data();

  // Only for debug -> check paths in the vector
  /*
     for (int i = 0; cpaths_ptr[i] != nullptr; i++) {
    std::cout << cpaths_ptr[i] << std::endl;
  }
  */

  // TODO: found a dynamic way to calculate the right size of cpaths_ptr
  int path_size = 1000;
  char **device_paths = (char **)malloc(path_size);
  cudaMalloc(&device_paths, path_size);
  cudaMemcpy(device_paths, cpaths_ptr, path_size, cudaMemcpyHostToDevice);
  char *target = search_target.data();
  search_target_file<<<1000, 1>>>(device_paths, target);
  cudaDeviceSynchronize();

  return 0;
}
