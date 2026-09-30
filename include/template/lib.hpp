#pragma once

#include <string>
#include <string_view>

namespace tmpl {

[[nodiscard]] std::string greet(std::string_view name);

} // namespace tmpl
