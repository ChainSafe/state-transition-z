const std = @import("std");
const testing = std.testing;
const block_root = @import("utils/block_root.zig");
const generate_state = @import("./generate_state.zig");

test {
    testing.refAllDecls(block_root);
    testing.refAllDecls(generate_state);
}
