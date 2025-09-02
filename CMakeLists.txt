cmake_minimum_required(VERSION 3.31)

if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(template)
    message(STATUS "Building 'libTemplate' as a standalone project.")
endif()

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

add_library(libTemplate STATIC)
target_include_directories(libTemplate PUBLIC include)
target_sources(libTemplate PRIVATE ${SOURCES})
set_target_properties(libTemplate PROPERTIES OUTPUT_NAME "template")

# A consuming project may want to build the tests, but not by default.
# The `BUILD_TESTING` option is a standard way to control this.
option(template_BUILD_TESTS "Build the example executable for the template library" OFF)
if (template_BUILD_TESTS)
    add_executable(template_test examples/main.cpp)
    target_link_libraries(template_test libTemplate)
    message(STATUS "Building optional test executable 'template_test'.")
endif ()