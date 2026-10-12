# Opt-in IR instrumentation PGO. Keep flags local to the project's own targets.
set(template_PGO "OFF" CACHE STRING "PGO mode: OFF, GENERATE or USE")
set_property(CACHE template_PGO PROPERTY STRINGS OFF GENERATE USE)
set(template_PGO_PROFILE "" CACHE FILEPATH "Merged LLVM profile for PGO USE")

if(NOT template_PGO MATCHES "^(OFF|GENERATE|USE)$")
    message(FATAL_ERROR "template_PGO must be OFF, GENERATE or USE")
endif()
if(template_PGO STREQUAL "OFF")
    return()
endif()
if(NOT CMAKE_CXX_COMPILER_ID MATCHES "^(Clang|AppleClang)$")
    message(FATAL_ERROR "template_PGO requires Clang and a matching llvm-profdata")
endif()
if(CMAKE_CONFIGURATION_TYPES OR NOT CMAKE_BUILD_TYPE STREQUAL "Release")
    message(FATAL_ERROR "template_PGO requires a single-configuration Release build")
endif()
if(template_COVERAGE OR template_MUTATION)
    message(FATAL_ERROR "PGO cannot be combined with coverage or mutation instrumentation")
endif()

if(template_PGO STREQUAL "GENERATE")
    # Override LLVM_PROFILE_FILE when training; the default stays inside build/.
    set(_pgo_flag "-fprofile-generate=${CMAKE_BINARY_DIR}/profiles")
else()
    if(NOT IS_ABSOLUTE "${template_PGO_PROFILE}" OR
       NOT EXISTS "${template_PGO_PROFILE}" OR IS_DIRECTORY "${template_PGO_PROFILE}")
        message(FATAL_ERROR "template_PGO_PROFILE must name an existing absolute .profdata file")
    endif()
    # configure_file tracks the input; a changed hash changes compile commands,
    # so replacing a profile rebuilds objects as well as relinking the binary.
    file(SHA256 "${template_PGO_PROFILE}" _pgo_hash)
    set(_pgo_copy "${CMAKE_BINARY_DIR}/pgo-${_pgo_hash}.profdata")
    configure_file("${template_PGO_PROFILE}" "${_pgo_copy}" COPYONLY)
    set(_pgo_flag "-fprofile-use=${_pgo_copy}")
endif()
target_compile_options(template_options INTERFACE "${_pgo_flag}")
target_link_options(template_options INTERFACE "${_pgo_flag}")
