# cuda-file-search
A Sample App to Show How CUDA can Improve How Fast The Search Process.

## TBD
Still work in progress. ✍(◔◡◔)

### How to
#### C++
Compile
```
g++ search.cpp -o search.out
```
Run
```
./search.out <your_target_file>
```
#### Cuda
Compile
```
nvcc -arch=sm_50 -Wno-deprecated-gpu-targets search.cu -o search_cuda.out
```
Run
```
./search.out <your_target_file>
```
or suit yourself here 
