#include "utils.hpp"

#include <fmt/format.h>

namespace utils {

void info(std::string_view s) {
  fmt::print("INFO: {}\n", s);
}

}  // namespace utils
