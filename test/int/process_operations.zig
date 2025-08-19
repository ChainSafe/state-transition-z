const std = @import("std");
const ssz = @import("consensus_types");
const config = @import("config");

const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;

const chain_config = config.mainnet_chain_config;
const preset = ssz.preset;

const processOperations = @import("state_transition").processOperations;

const SignedBlock = @import("state_transition").SignedBlock;
const SignedBeaconBlock = @import("state_transition").SignedBeaconBlock;

test "process operations" {
    const allocator = std.testing.allocator;

    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();

    const beacon_block: ssz.electra.SignedBeaconBlock.Type = ssz.electra.SignedBeaconBlock.default_value;
    const signed_beacon_block = SignedBeaconBlock{ .electra = &beacon_block };
    const block = SignedBlock{ .regular = &signed_beacon_block };
    try processOperations(allocator, test_state.cached_state, &block.getBeaconBlockBody(), .{});
}
