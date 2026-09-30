#include "template/lib.hpp"

#include <format>

namespace tmpl {

std::string greet(std::string_view name) {
    return std::format("Hello, {}!", name);
}

} // namespace tmpl
