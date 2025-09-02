cmake_minimum_required(VERSION 3.31)
project(template)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if (UNIX AND NOT APPLE)
    set(CMAKE_CXX_FLAGS "-O3 -flto -Wpedantic -Wall -Wextra -Wsign-conversion -Wconversion")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
    message("Compiling for Linux with flags: ${CMAKE_CXX_FLAGS}")
elseif (WIN32)
    set(CMAKE_CXX_FLAGS "")
    message("Compiling for Windows with flags: ${CMAKE_CXX_FLAGS}")
endif ()

file(GLOB_RECURSE SOURCES src/*.cpp)

add_library(template STATIC)
target_include_directories(template PUBLIC include)
target_sources(template PRIVATE ${SOURCES})

add_executable(template_test examples/main.cpp)
target_link_libraries(template_test template)
