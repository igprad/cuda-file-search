#include <chrono>
#include <filesystem>
#include <iostream>

namespace fs = std::filesystem;

int main(int argc, char **argv) {
  std::string search_target = argv[1];
  std::cout << "Your target file name : " << search_target << std::endl;

  bool found = false;
  fs::path current_path = fs::current_path();
  std::cout << "Target directory : " << current_path << std::endl;
  auto dir_iterator = fs::recursive_directory_iterator{current_path};
  auto start = std::chrono::high_resolution_clock::now();
  // TODO: translate this loop to device cuda (*_*)
  for (const auto &dir_entry : dir_iterator) {
    auto current_path = dir_entry.path();
    for (auto iterator = current_path.begin(); iterator != current_path.end();
         ++iterator) {
      if (iterator->has_filename()) {
        std::string file_name = iterator->string();
        if (search_target.compare(file_name) == 0) {
          std::cout << "Found the target at " << current_path << std::endl;
          found = true;
        }
      }
    }
  }
  auto end = std::chrono::high_resolution_clock::now();
  if (!found) {
    std::cout << "Your target file is not found." << std::endl;
  }
  auto duration =
      std::chrono::duration_cast<std::chrono::microseconds>(end - start);
  std::cout << "Search time spent : " << duration.count() << " microseconds."
            << std::endl;
  return 0;
}
