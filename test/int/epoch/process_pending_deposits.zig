const std = @import("std");
const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;
const state_transition = @import("state_transition");
const ReusedEpochTransitionCache = state_transition.ReusedEpochTransitionCache;
const EpochTransitionCache = state_transition.EpochTransitionCache;
const testProcessPendingDeposits = @import("./process_epoch_fn.zig").getTestProcessFn(state_transition.processPendingDeposits, false, false).testProcessEpochFn;

test "processPendingDeposits - sanity" {
    try testProcessPendingDeposits();
}
