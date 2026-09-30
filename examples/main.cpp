#include "template/lib.hpp"

#include <cstdio>
#include <cstdlib>
#include <exception>
#include <print>

int main() {
    try {
        std::println("{}", tmpl::greet("world"));
    } catch (const std::exception &e) {
        std::fputs(e.what(), stderr);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
