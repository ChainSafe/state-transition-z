const std = @import("std");
const ssz = @import("consensus_types");
const config = @import("config");

const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;

const chain_config = config.mainnet_chain_config;
const preset = ssz.preset;

const processWithdrawals = @import("state_transition").processWithdrawals;
const getExpectedWithdrawalsResult = @import("state_transition").getExpectedWithdrawalsResult;
const SignedBlock = @import("state_transition").SignedBlock;
const SignedBeaconBlock = @import("state_transition").SignedBeaconBlock;

test "process withdrawals - sanity" {
    const allocator = std.testing.allocator;

    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();

    var ewr = try getExpectedWithdrawalsResult(allocator, test_state.cached_state);
    defer ewr.deinit(allocator);
    try processWithdrawals(allocator, test_state.cached_state, ewr);
}
