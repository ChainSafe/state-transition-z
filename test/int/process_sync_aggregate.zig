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

    const beacon_block = BeaconBlock{ .electra = &message };
    const block = Block{ .regular = beacon_block };
    try processSyncAggregate(allocator, test_state.cached_state, block, true);
}

const std = @import("std");
const ssz = @import("consensus_types");
const config = @import("config");

const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("state_transition").test_utils.TestCachedBeaconStateAllForks;

const state_transition = @import("state_transition");
const processSyncAggregate = state_transition.processSyncAggregate;
const Block = state_transition.Block;
const SignedBlock = state_transition.SignedBlock;
const BeaconBlock = state_transition.BeaconBlock;
const SignedBeaconBlock = state_transition.SignedBeaconBlock;
const G2_POINT_AT_INFINITY = @import("constants").G2_POINT_AT_INFINITY;
