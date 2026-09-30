cmake_minimum_required(VERSION 3.30)

project(template LANGUAGES CXX)

if(PROJECT_IS_TOP_LEVEL AND NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

option(template_BUILD_TESTS "Build tests" ${PROJECT_IS_TOP_LEVEL})
option(template_BUILD_EXAMPLES "Build examples" ${PROJECT_IS_TOP_LEVEL})
option(template_NATIVE "Optimize for the host CPU (-march=native)" OFF)

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
  FetchContent_MakeAvailable(googletest)

  add_executable(template_tests tests/test_lib.cpp)
  target_link_libraries(template_tests PRIVATE template template_options GTest::gtest_main)

  include(GoogleTest)
  gtest_discover_tests(template_tests)
endif()
