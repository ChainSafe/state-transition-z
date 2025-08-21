const std = @import("std");
const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;
const state_transition = @import("state_transition");
const ReusedEpochTransitionCache = state_transition.ReusedEpochTransitionCache;
const EpochTransitionCache = state_transition.EpochTransitionCache;
const TestRunner = @import("./test_runner.zig").TestRunner;

test "processHistoricalSummariesUpdate - sanity" {
    try TestRunner(state_transition.processHistoricalSummariesUpdate, .{
        .alloc = true,
        .err_return = true,
        .void_return = true,
    }).testProcessEpochFn();
}
