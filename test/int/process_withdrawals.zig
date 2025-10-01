test "process withdrawals - sanity" {
    const allocator = std.testing.allocator;

    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();
    var withdrawals_result = WithdrawalsResult{
        .withdrawals = try Withdrawals.initCapacity(
            allocator,
            preset.MAX_WITHDRAWALS_PER_PAYLOAD,
        ),
    };
    defer withdrawals_result.withdrawals.deinit(allocator);
    var withdrawal_balances = std.AutoHashMap(ValidatorIndex, usize).init(allocator);
    defer withdrawal_balances.deinit();

    try getExpectedWithdrawalsResult(allocator, &withdrawals_result, &withdrawal_balances, test_state.cached_state);
    try processWithdrawals(test_state.cached_state, withdrawals_result);
}

const std = @import("std");

const state_transition = @import("state_transition");
const preset = @import("params").preset;
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const processWithdrawals = state_transition.processWithdrawals;
const getExpectedWithdrawalsResult = state_transition.getExpectedWithdrawalsResult;
const WithdrawalsResult = state_transition.WithdrawalsResult;
const ssz = @import("consensus_types");
const Withdrawals = ssz.capella.Withdrawals.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
