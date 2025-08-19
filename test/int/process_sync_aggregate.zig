test "process sync aggregate - sanity" {
    const allocator = std.testing.allocator;

    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();

    var sync_aggregate: ssz.electra.SyncAggregate.Type = ssz.electra.SyncAggregate.default_value;
    sync_aggregate.sync_committee_signature = G2_POINT_AT_INFINITY;
    var body: ssz.electra.BeaconBlockBody.Type = ssz.electra.BeaconBlockBody.default_value;
    body.sync_aggregate = sync_aggregate;

    var message: ssz.electra.BeaconBlock.Type = ssz.electra.BeaconBlock.default_value;
    message.body = body;

    var beacon_block: ssz.electra.SignedBeaconBlock.Type = ssz.electra.SignedBeaconBlock.default_value;
    beacon_block.message = message;
    const signed_beacon_block = SignedBeaconBlock{ .electra = &beacon_block };
    const block = SignedBlock{ .regular = &signed_beacon_block };

    try processSyncAggregate(allocator, test_state.cached_state, &block, null);
}

const std = @import("std");
const ssz = @import("consensus_types");
const config = @import("config");

const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;

const processSyncAggregate = @import("state_transition").processSyncAggregate;
const SignedBlock = @import("state_transition").SignedBlock;
const SignedBeaconBlock = @import("state_transition").SignedBeaconBlock;
const G2_POINT_AT_INFINITY = blk: {
    const hex_string = "c000000000000000000000000000000000000000000000000000000000000000" ++ "0000000000000000000000000000000000000000000000000000000000000000" ++ "0000000000000000000000000000000000000000000000000000000000000000";
    const byte_array_len = hex_string.len / 2;
    var bytes: [byte_array_len]u8 = undefined;
    _ = std.fmt.hexToBytes(&bytes, hex_string) catch unreachable;
    break :blk bytes;
};
