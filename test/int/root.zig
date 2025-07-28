const std = @import("std");
const testing = std.testing;
const epoch_transition_cache = @import("./cache/epoch_transition_cache.zig");
const process_justification_and_finalization = @import("./epoch/process_justification_and_finalization.zig");
const process_rewards_and_penalties = @import("./epoch/process_rewards_and_penalties.zig");

test {
    testing.refAllDecls(epoch_transition_cache);
    testing.refAllDecls(process_justification_and_finalization);
    testing.refAllDecls(process_rewards_and_penalties);
}
