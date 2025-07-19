const std = @import("std");
const testing = std.testing;
const epoch_transition_cache = @import("./cache/epoch_transition_cache.zig");
const process_justification_and_finalization = @import("./epoch/process_justification_and_finalization.zig");

test {
    testing.refAllDecls(epoch_transition_cache);
    testing.refAllDecls(process_justification_and_finalization);
}
