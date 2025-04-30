message(STATUS "Building template")

file(GLOB_RECURSE SOURCES src/*.cpp)
file(GLOB_RECURSE HEADERS include/*.hpp)
add_library(template STATIC ${SOURCES} ${HEADERS})

# Include directories for consumers of template
target_include_directories(template PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_executable(template_test examples/main.cpp)
target_link_libraries(template_test template)
