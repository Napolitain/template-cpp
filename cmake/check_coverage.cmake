# Fails when total line coverage is below MIN.
# cmake -DLLVM_COV=... -DMIN=80 -DARGS="<binary>,-instr-profile=...,..." -P check_coverage.cmake
string(REPLACE "," ";" ARGS "${ARGS}")
execute_process(
    COMMAND ${LLVM_COV} export -summary-only ${ARGS}
    OUTPUT_VARIABLE _json
    COMMAND_ERROR_IS_FATAL ANY
)
string(JSON _pct GET "${_json}" data 0 totals lines percent)
if(_pct LESS MIN)
    message(FATAL_ERROR "Line coverage ${_pct}% is below ${MIN}%")
endif()
message(STATUS "Line coverage ${_pct}% (min ${MIN}%)")
