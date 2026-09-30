#include "template/lib.hpp"

#include <gtest/gtest.h>

TEST(Greet, SaysHello) { EXPECT_EQ(tmpl::greet("world"), "Hello, world!"); }
