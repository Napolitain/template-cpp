#include "template/lib.hpp"

#include <gtest/gtest.h>
#include <rapidcheck/gtest.h>

#include <string>

TEST(Greet, SaysHello) { EXPECT_EQ(tmpl::greet("world"), "Hello, world!"); }

// Property-based test: RapidCheck generates names and shrinks failures to a
// minimal case.
RC_GTEST_PROP(Greet, WrapsAnyName, (const std::string &name)) {
    RC_ASSERT(tmpl::greet(name) == "Hello, " + name + "!");
}
