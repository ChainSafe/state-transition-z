const std = @import("std");
const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;
const state_transition = @import("state_transition");
const ReusedEpochTransitionCache = state_transition.ReusedEpochTransitionCache;
const EpochTransitionCache = state_transition.EpochTransitionCache;
const TestRunner = @import("./test_runner.zig").TestRunner;

test "processEth1DataReset - sanity" {
    try TestRunner(state_transition.processEth1DataReset, .{
        .alloc = false,
        .err_return = false,
        .void_return = true,
    }).testProcessEpochFn();
}
