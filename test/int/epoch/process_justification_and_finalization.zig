const std = @import("std");
const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;
const state_transition = @import("state_transition");
const ReusedEpochTransitionCache = state_transition.ReusedEpochTransitionCache;
const EpochTransitionCache = state_transition.EpochTransitionCache;
const getTestProcessFn = @import("./process_epoch_fn.zig").getTestProcessFn;

test "processJustificationAndFinalization - sanity" {
    try getTestProcessFn(state_transition.processJustificationAndFinalization, .{
        .alloc = false,
        .err_return = true,
        .void_return = true,
    }).testProcessEpochFn();
}
