cmake_minimum_required(VERSION 4.3)

project(template LANGUAGES CXX)

if(PROJECT_IS_TOP_LEVEL AND NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

option(template_BUILD_TESTS "Build tests" ${PROJECT_IS_TOP_LEVEL})
option(template_BUILD_EXAMPLES "Build examples" ${PROJECT_IS_TOP_LEVEL})
option(template_NATIVE "Optimize for the host CPU (-march=native)" ON)
option(template_COVERAGE "Instrument for clang source-based coverage" OFF)
set(template_COVERAGE_MIN 80 CACHE STRING "Minimum line coverage (%) for the coverage target")
set(template_MULL_PLUGIN "" CACHE FILEPATH "Mull IR frontend plugin; set to build mutants for mull-runner")

set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# No C++ modules here; keeps compile_commands.json usable by clang-tidy/cppcheck without a build.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# Shared settings for our own targets (not third-party deps or consumers).
add_library(template_options INTERFACE)
target_compile_options(template_options INTERFACE
    -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow
    $<$<BOOL:${PROJECT_IS_TOP_LEVEL}>:-Werror>
    $<$<CONFIG:Release>:-flto=full>
    $<$<BOOL:${template_NATIVE}>:-march=native>
)
target_link_options(template_options INTERFACE
    $<$<CONFIG:Release>:-flto=full -s>
)
if(template_MULL_PLUGIN)
    # Only our targets get mutants; mull.yml excludes tests/.
    target_compile_options(template_options INTERFACE -fpass-plugin=${template_MULL_PLUGIN} -g -grecord-command-line)
endif()

add_library(template src/lib.cpp)
add_library(template::template ALIAS template)
target_include_directories(template PUBLIC include)
target_link_libraries(template PRIVATE $<BUILD_INTERFACE:template_options>)

if(template_BUILD_EXAMPLES)
    add_executable(template_example examples/main.cpp)
    target_link_libraries(template_example PRIVATE template template_options)
endif()

if(template_BUILD_TESTS)
    enable_testing()
    include(FetchContent)
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    FetchContent_Declare(googletest
        URL https://github.com/google/googletest/archive/refs/tags/v1.18.0.tar.gz
        SYSTEM
        FIND_PACKAGE_ARGS NAMES GTest
    )
    # Property-based testing; no tagged releases, so pinned to a commit.
    set(RC_ENABLE_GTEST ON CACHE BOOL "" FORCE)
    FetchContent_Declare(rapidcheck
        URL https://github.com/emil-e/rapidcheck/archive/6e8dadfdafa3a74eabb52ead87f8787f72eccd0b.tar.gz
        SYSTEM
    )
    FetchContent_MakeAvailable(googletest rapidcheck)

    add_executable(template_tests tests/test_lib.cpp)
    target_link_libraries(template_tests PRIVATE template template_options GTest::gtest_main rapidcheck_gtest)

    include(GoogleTest)
    gtest_discover_tests(template_tests)
endif()

if(template_COVERAGE)
    target_compile_options(template_options INTERFACE -fprofile-instr-generate -fcoverage-mapping)
    target_link_options(template_options INTERFACE -fprofile-instr-generate)

    # Prefer the LLVM tools that ship next to the compiler (e.g. /usr/lib/llvm-22/bin).
    file(REAL_PATH "${CMAKE_CXX_COMPILER}" _cxx_real)
    get_filename_component(_llvm_bin "${_cxx_real}" DIRECTORY)
    find_program(LLVM_PROFDATA llvm-profdata HINTS "${_llvm_bin}" REQUIRED)
    find_program(LLVM_COV llvm-cov HINTS "${_llvm_bin}" REQUIRED)

    set(_cov_dir "${CMAKE_BINARY_DIR}/coverage")
    set(_cov_args $<TARGET_FILE:template_tests> -instr-profile=${_cov_dir}/coverage.profdata
        -ignore-filename-regex=/_deps/ -ignore-filename-regex=/tests/)
    add_custom_target(coverage
        COMMAND ${CMAKE_COMMAND} -E rm -rf ${_cov_dir}
        COMMAND ${CMAKE_COMMAND} -E env LLVM_PROFILE_FILE=${_cov_dir}/%p.profraw
            ${CMAKE_CTEST_COMMAND} --test-dir ${CMAKE_BINARY_DIR} --output-on-failure
        COMMAND ${LLVM_PROFDATA} merge -sparse ${_cov_dir}/*.profraw -o ${_cov_dir}/coverage.profdata
        COMMAND ${LLVM_COV} report ${_cov_args}
        COMMAND ${LLVM_COV} show ${_cov_args} -format=html -output-dir=${_cov_dir}/html
        COMMAND ${CMAKE_COMMAND} -DLLVM_COV=${LLVM_COV} -DMIN=${template_COVERAGE_MIN}
            "-DARGS=$<JOIN:${_cov_args},$<COMMA>>" -P ${PROJECT_SOURCE_DIR}/cmake/check_coverage.cmake
        DEPENDS template_tests
        COMMENT "Coverage report: ${_cov_dir}/html/index.html"
    )
endif()
