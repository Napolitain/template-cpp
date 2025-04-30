message(STATUS "Building template")

file(GLOB_RECURSE SOURCES src/*.cpp)
file(GLOB_RECURSE HEADERS include/*.hpp)

add_executable(template_service src/main.cpp)
target_link_libraries(template_service template)
