# template-cpp

Minimal C++26 library template: clang, CMake + Ninja, dependencies via `FetchContent` (GoogleTest, RapidCheck), hooks via [prek](https://prek.j178.dev).

```
include/template/   public headers
src/                library sources
examples/           example executable
tests/              GoogleTest + RapidCheck tests
cmake/              helper scripts
```

```sh
prek install                         # install pre-commit + pre-push hooks
cmake --workflow --preset debug      # configure + build + test
cmake --workflow --preset release    # -O3, full LTO, -march=native, stripped
cmake --workflow --preset coverage   # tests + coverage gate → build/coverage/coverage/html
./build/release/template_example
prek run -a                          # pre-commit hooks
prek run -a --hook-stage pre-push    # pre-push hooks
```

- pre-commit: `clang-format -i`
- pre-push: `clang-tidy --fix --fix-notes`, `cppcheck` (no autofix available), tests + coverage gate (`coverage` preset)

Opinionated defaults: Release build type, `-march=native` everywhere (`-Dtemplate_NATIVE=OFF` for portable binaries), `-Werror` when top-level.

## Coverage

clang source-based coverage of `src/` and `include/` (tests and `_deps` excluded). The `coverage` target fails below `template_COVERAGE_MIN` (default 80% lines):

```sh
cmake --preset coverage -Dtemplate_COVERAGE_MIN=90
```

## Property-based testing

[RapidCheck](https://github.com/emil-e/rapidcheck) with GoogleTest integration; see `tests/test_lib.cpp`. Properties run as normal tests under `ctest`.

```cpp
RC_GTEST_PROP(Sort, IsIdempotent, (std::vector<int> v)) {
    std::ranges::sort(v);
    auto once = v;
    std::ranges::sort(v);
    RC_ASSERT(v == once);
}
```

Replay a failure with `RC_PARAMS="reproduce=<string printed on failure>"`.

## Mutation testing

[Mull](https://mull.readthedocs.io) (LLVM-based), on demand and weekly in CI (`.github/workflows/mutation.yml`); fails if any mutant survives. Install the package matching your clang major from the [releases](https://github.com/mull-project/mull/releases) (Ubuntu/Debian `.deb`, RHEL `.rpm`, macOS `.zip`), then:

```sh
prek run --hook-stage manual mull --all-files
```

The `mutation` preset sets `template_MULL_PLUGIN=/usr/lib/mull-ir-frontend-21`, which only instruments this project's targets. For another LLVM version, change it and `mull-runner-21` in `prek.toml`. Mutators and excluded paths are in `mull.yml`.

## Using as a dependency

Tests, examples and `-Werror` are only enabled when this is the top-level project.

```cmake
FetchContent_Declare(template GIT_REPOSITORY https://github.com/Napolitain/template-cpp GIT_TAG main)
FetchContent_MakeAvailable(template)
target_link_libraries(app PRIVATE template::template)
```

Add your own dependencies with `FetchContent_Declare(... FIND_PACKAGE_ARGS ...)` so a system package is used when available.
