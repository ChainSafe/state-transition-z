const std = @import("std");
const testing = std.testing;
const block_root = @import("utils/block_root.zig");

test {
    testing.refAllDecls(block_root);
}
