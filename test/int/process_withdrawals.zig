test "process withdrawals - sanity" {
    const allocator = std.testing.allocator;

    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();

    var ewr = try getExpectedWithdrawalsResult(allocator, test_state.cached_state);
    defer ewr.deinit(allocator);
    try processWithdrawals(test_state.cached_state, ewr);
}

const std = @import("std");

const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;

const processWithdrawals = @import("state_transition").processWithdrawals;
const getExpectedWithdrawalsResult = @import("state_transition").getExpectedWithdrawalsResult;
