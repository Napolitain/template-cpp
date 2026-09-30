# template-cpp

Minimal C++26 library template: clang, CMake + Ninja, dependencies via `FetchContent` (GoogleTest), hooks via [prek](https://prek.j178.dev).

```
include/template/   public headers
src/                library sources
examples/           example executable
tests/              GoogleTest tests
```

```sh
prek install                         # install pre-commit + pre-push hooks
cmake --workflow --preset debug      # configure + build + test
cmake --workflow --preset release    # -O3, full LTO, stripped
./build/release/template_example
prek run -a                          # pre-commit hooks
prek run -a --hook-stage pre-push    # pre-push hooks
```

- pre-commit: `clang-format -i`
- pre-push: `clang-tidy --fix --fix-notes`, `cppcheck` (no autofix available)

Release is the default build type when none is given. `-Dtemplate_NATIVE=ON` adds `-march=native`.

## Using as a dependency

Tests, examples and `-Werror` are only enabled when this is the top-level project.

```cmake
FetchContent_Declare(template GIT_REPOSITORY https://github.com/Napolitain/template-cpp GIT_TAG main)
FetchContent_MakeAvailable(template)
target_link_libraries(app PRIVATE template::template)
```

Add your own dependencies with `FetchContent_Declare(... FIND_PACKAGE_ARGS ...)` so a system package is used when available.
