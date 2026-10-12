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
cmake --workflow --preset lint       # clang-tidy --fix + cppcheck
cmake --workflow --preset mutation   # Mull (see below)
./build/release/template_example
prek run -a                          # pre-commit hooks
prek run -a --hook-stage pre-push    # pre-push hooks
```

- pre-commit: `clang-format -i`
- pre-push: `lint` preset (`clang-tidy --fix --fix-notes` + `cppcheck`, no autofix available), `coverage` preset (tests + coverage gate)

## Optional Nix shell

Installing the tools directly on NixOS (or another OS) remains supported. The
optional shell supports x86_64/aarch64 Linux and Apple Silicon macOS. With Nix
flakes enabled:

```sh
nix develop --command "$SHELL"       # keep your shell, aliases and prompt
# Or: nix develop                   # use Nix's default Bash shell
```

Then run the normal development commands in this README. Each template has its own
`flake.nix` and `flake.lock`, using `github:NixOS/nixpkgs/nixpkgs-unstable`.
To refresh to the latest unstable packages, run `nix flake update nixpkgs`,
then leave and re-enter the shell. Commit the updated lock file with your project.

The shell supplies the matching Nixpkgs LLVM compiler, formatter, linter and
coverage tools, plus CMake, Ninja and cppcheck. Mull remains a separate optional
installation matching the shell's clang major (see Mutation testing below).

## Complexity

The existing `readability-*` clang-tidy checks include
`readability-function-cognitive-complexity`. Its maximum is explicitly set to 15
in `.clang-tidy` (upstream default: 25), with violations treated as errors by the
pre-push hook and CI. It checks project sources, examples and tests. Refactoring
is manual. There is no separate cyclomatic-complexity gate in this toolchain.

Everything runs through CMake presets and targets (`tidy`, `cppcheck`, `coverage`, `mutation`); hooks only call `cmake --workflow`.

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

The `mutation` preset turns on `template_MUTATION`, which finds `mull-ir-frontend-<N>` and `mull-runner-<N>` for your clang major and only instruments this project's targets. Mutators and excluded paths are in `mull.yml`.

## Using as a dependency

Tests, examples and `-Werror` are only enabled when this is the top-level project.

```cmake
FetchContent_Declare(template GIT_REPOSITORY https://github.com/Napolitain/template-cpp GIT_TAG main)
FetchContent_MakeAvailable(template)
target_link_libraries(app PRIVATE template::template)
```

Add your own dependencies with `FetchContent_Declare(... FIND_PACKAGE_ARGS ...)` so a system package is used when available.

## Profile-guided optimization

Opt-in release builds retain **full LTO**. Use Clang/LLD 21+ with matching
`llvm-profdata` and `llvm-profgen` (provided by `nix develop`). AutoFDO and
Propeller additionally require Linux `perf`, hardware branch-stack sampling and
permission to record it. Normal builds require no profiles.
On Linux the helper uses LLD for the baseline and every optimized variant.

Create an executable `train.sh` that runs `"$1"` with representative inputs;
the helper passes it the absolute training-binary path. For a PGO smoke test only,
replace `./train.sh` with `env` to run the greeting once. Sampling needs a
longer CPU workload with samples inside your executable.

```sh
./tools/perf-build baseline
./tools/perf-build pgo -- ./train.sh             # instrument, train, merge, rebuild
./tools/perf-build autofdo -- ./train.sh         # perf, llvm-profgen, rebuild
./tools/perf-build propeller -- ./train.sh       # perf, arrange blocks/functions
./tools/perf-build propeller-pgo -- ./train.sh   # PGO, then fresh layout sampling
./tools/perf-build propeller-autofdo -- ./train.sh
```

Pick one optimization mode. Outputs are `build/pgo-baseline/template_example`
and `build/<mode>-use/template_example`. Set `PERF_TARGET` to your CMake target
and, if needed, `PERF_BINARY` to its path relative to the build directory.
Profiles and an input record stay in fresh directories under `build/pgo/`.
Run builds serially; collection and use must share source, toolchain and flags.

**Propeller converter, one-time setup:** `tools/build-propeller` fetches a pinned
[upstream converter](https://github.com/google/llvm-propeller) and its dependencies.
On Linux with Nix:

```sh
nix develop .#propeller
./tools/build-propeller
export PATH="$PWD/build/tools/llvm-propeller/build/propeller:$PATH"
```

Without Nix, install upstream's build prerequisites first (Clang, CMake, Ninja,
Python, pkg-config, libelf, OpenSSL, zlib and zstd development files), then run the
same helper. The source build can take several minutes and multiple GB of disk.
Install/use your host's `perf` separately. In a Nix shell, set
`NIX_ENFORCE_NO_NATIVE=0` if you want the template's host-native CPU tuning.

Sampling defaults to `perf record -e cycles:u -j any,u -F 999`; override
`PERF_EVENT` / `PERF_FREQUENCY` for your PMU. For example, an Intel hybrid
CPU may need `PERF_EVENT=cpu_core/cycles/u` and a workload pinned to a P-core.
Failed collection/conversion stops the build. Inspect the saved profiles for
application hot paths; recollect after changing source, compiler or workload.
Review missing-profile and symbol-ordering warnings before adopting a build.

For manual/remote collection, use the `pgo-`, `autofdo-` or `propeller-`
`generate`/`use` configure and build presets. Set `template_PGO_PROFILE`
(instrumentation or sample profile), or both `template_PROPELLER_CC_PROFILE` and
`template_PROPELLER_LD_PROFILE`, to absolute files on the use configure command.
Propeller can combine with `-Dtemplate_PGO=USE` or `SAMPLE_USE`. Collection
binaries keep symbols/maps; use binaries are stripped. Profile changes trigger
recompilation, including LTO. Tests, coverage and mutation are excluded from training.

Check correctness of the final executable, then compare it with the baseline on
**separate evaluation inputs**, using repeated runs:

```sh
hyperfine --warmup 3 --runs 20 './evaluate.sh ./build/pgo-baseline/template_example' \
    './evaluate.sh ./build/autofdo-use/template_example'
perf stat -r 5 -e cycles,instructions,branches,branch-misses -- \
    ./evaluate.sh ./build/autofdo-use/template_example
```

Measure both variants' counters, latency, memory and size. Profiles can regress
other workloads; keep the baseline when gains are absent or within noise.
See [Clang PGO/AutoFDO](https://clang.llvm.org/docs/UsersManual.html#profile-guided-optimization)
for profile formats and sampling details.
