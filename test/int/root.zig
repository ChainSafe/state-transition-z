const std = @import("std");
const testing = std.testing;
const block_root = @import("utils/block_root.zig");
const generate_state = @import("./generate_state.zig");
const epoch_transition_cache = @import("./cache/epoch_transition_cache.zig");

test {
    testing.refAllDecls(block_root);
    testing.refAllDecls(generate_state);
    testing.refAllDecls(epoch_transition_cache);
}
