const std = @import("std");
const testing = std.testing;
pub const operations = @import("./test_case/operations_tests.zig");

test {
    testing.refAllDecls(operations);
}
