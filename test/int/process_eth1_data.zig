test "process eth1 data - sanity" {
    const allocator = std.testing.allocator;

    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();

    const beacon_block: ssz.electra.SignedBeaconBlock.Type = ssz.electra.SignedBeaconBlock.default_value;
    const signed_beacon_block = SignedBeaconBlock{ .electra = &beacon_block };
    const block = SignedBlock{ .regular = &signed_beacon_block };
    try processEth1Data(allocator, test_state.cached_state, block.getBeaconBlockBody().eth1Data());
}

const std = @import("std");
const ssz = @import("consensus_types");

const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;

const processEth1Data = @import("state_transition").processEth1Data;
const SignedBlock = @import("state_transition").SignedBlock;
const SignedBeaconBlock = @import("state_transition").SignedBeaconBlock;
