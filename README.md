# Using Nim for serving PyTorch models

Trying to replicate the [Loading a PyTorch Model in C++](https://pytorch.org/tutorials/advanced/cpp_export.html#step-3-loading-your-script-module-in-c)
example using Nim.

Currently compiles with:

```
nim cpp serialization.nim
```

and runs with:

```
LD_LIBRARY_PATH="./libtorch/lib" ./serialization
```

Think have to set `-Wl,-rpath,$(pwd)/libtorch/lib` in order to not set 
`LD_LIBRARY_PATH`.

## Analyzing Compilation and Linking

### C++ Sample program

When compile the sample program, get the following from the cmake compilation steps.

Compiling:

```
/usr/bin/c++ \
  -isystem /home/foobar/programming/torch_serialization_experiments/libtorch/include \
  -isystem /home/foobar/programming/torch_serialization_experiments/libtorch/include/torch/csrc/api/include \
  -D_GLIBCXX_USE_CXX11_ABI=0 \
  -std=c++11 \
  -std=gnu++11 \
  -o CMakeFiles/example-app.dir/example-app.cpp.o \
  -c /home/foobar/programming/torch_serialization_experiments/example-app.cpp
```

Linking:

```
/usr/bin/c++ -rdynamic CMakeFiles/example-app.dir/example-app.cpp.o \
  -o example-app -Wl,-rpath,/home/foobar/programming/torch_serialization_experiments/libtorch/lib \
  ../libtorch/lib/libtorch.so ../libtorch/lib/libc10.so \
  -Wl,--no-as-needed,/home/foobar/programming/torch_serialization_experiments/libtorch/lib/libcaffe2.so \
  -Wl,--as-needed ../libtorch/lib/libc10.so \
  -lpthread
```

### Nim Program

Compiling:

```
g++ -c -w -w -fpermissive -I./libtorch/include/ \
  -I'/home/foobar/.choosenim/toolchains/nim-#devel/lib' \
  -I/home/foobar/programming/torch_serialization_experiments \
  -o /home/foobar/.cache/nim/serialization_d/serialization.nim.cpp.o \
  /home/foobar/.cache/nim/serialization_d/serialization.nim.cpp 
```

Linking:

```
g++ -o /home/foobar/programming/torch_serialization_experiments/serialization  \
  /home/foobar/.cache/nim/serialization_d/stdlib_io.nim.cpp.o \
  /home/foobar/.cache/nim/serialization_d/stdlib_system.nim.cpp.o \
  /home/foobar/.cache/nim/serialization_d/stdlib_times.nim.cpp.o \
  /home/foobar/.cache/nim/serialization_d/stdlib_os.nim.cpp.o \
  '/home/foobar/.cache/nim/serialization_d/_7_7.nimble7pkgs7nimline-#HEAD7nimline.nim.cpp.o' \
  /home/foobar/.cache/nim/serialization_d/serialization.nim.cpp.o  \
  -lm -lrt -L/home/foobar/programming/torch_serialization_experiments/libtorch/lib \
  -ltorch -lcaffe2 -lcaffe2_detectron_ops -lc10 -lfoxi -ldl
```

Was able to get this working by making sure had the same ABI flag as above when
compiling Nim:

```nim
nimline.cppdefines("_GLIBCXX_USE_CXX11_ABI=0")
```

In order to do more than just load the model, need to be able to get data in
(Nim sequence to tensor) and get data out (model.forward to Nim sequence).
Ideally want to be able to interop with the existing nimtorch library, but
don't quite know where C++ types and nimtorch types interact yet (looking at
torch/torch_cpp.nim for some of the wrappers around ATen types).