#include <algorithm>
#include <filesystem>
#include <iostream>
#include <iterator>
#include <vector>

#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <device_launch_parameters.h>

namespace fs = std::filesystem;

__global__ void search_target_file(char **paths, char *target_file_name) {}

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
  for (int i = 0; cpaths_ptr[i] != nullptr; i++) {
    std::cout << cpaths_ptr[i] << std::endl;
  }

  /*
   * TODO: fix the transformation and device (global) func since in device
   * std::string package was not available. So need to pass pointer of char
   * pointer (char **) instead.
   */
  // Transform the vectors to device ready ptrs
  /*std::string *device_paths =
      (std::string *)malloc(sizeof(std::string) * path_size);
  cudaMalloc(&device_paths, sizeof(std::string) * path_size);
  cudaMemcpy(device_paths, paths, sizeof(std::string) * path_size,
             cudaMemcpyHostToDevice);
             */

  // Execute the device function to find the file, pass back to host for bool
  // result (?)
  return 0;
}
