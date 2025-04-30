cmake_minimum_required(VERSION 3.22)
project(cpp)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# Set some default CXXFLAGS and LDFLAGS
# -march=native
set(CMAKE_CXX_FLAGS "-O3 -flto -Wpedantic -Wall -Wextra -Wsign-conversion -Wconversion")

# Add common/shared library or module
add_subdirectory(libs)
add_subdirectory(services)
