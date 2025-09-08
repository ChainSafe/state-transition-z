test "process withdrawals - sanity" {
    const allocator = std.testing.allocator;

    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();

    var ewr = try getExpectedWithdrawalsResult(allocator, test_state.cached_state);
    defer ewr.deinit(allocator);
    try processWithdrawals(test_state.cached_state, ewr);
}

const std = @import("std");

const state_transition = @import("state_transition");
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const processWithdrawals = state_transition.processWithdrawals;
const getExpectedWithdrawalsResult = state_transition.getExpectedWithdrawalsResult;
