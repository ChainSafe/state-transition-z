const std = @import("std");
const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;
const state_transition = @import("state_transition");
const ReusedEpochTransitionCache = state_transition.ReusedEpochTransitionCache;
const EpochTransitionCache = state_transition.EpochTransitionCache;
const getTestProcessFn = @import("./process_epoch_fn.zig").getTestProcessFn;

test "processRegistryUpdates - sanity" {
    try getTestProcessFn(state_transition.processRegistryUpdates, .{
        .no_alloc = true,
        .no_err_return = false,
        .no_void_return = false,
    }).testProcessEpochFn();
}
