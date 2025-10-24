test "process execution payload - sanity" {
    const allocator = std.testing.allocator;

    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();

    var execution_payload: ssz.electra.ExecutionPayload.Type = ssz.electra.ExecutionPayload.default_value;
    execution_payload.timestamp = test_state.cached_state.state.genesisTime() + test_state.cached_state.state.slot() * config.mainnet_chain_config.SECONDS_PER_SLOT;
    var body: ssz.electra.BeaconBlockBody.Type = ssz.electra.BeaconBlockBody.default_value;
    body.execution_payload = execution_payload;

    var message: ssz.electra.BeaconBlock.Type = ssz.electra.BeaconBlock.default_value;
    message.body = body;

    const beacon_block = BeaconBlock{ .electra = &message };
    const block = Block{ .regular = beacon_block };

    try processExecutionPayload(
        allocator,
        test_state.cached_state,
        block.beaconBlockBody(),
        .{ .execution_payload_status = .valid, .data_availability_status = .available },
    );
}

const std = @import("std");
const ssz = @import("consensus_types");
const config = @import("config");

const state_transition = @import("state_transition");
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const processExecutionPayload = state_transition.processExecutionPayload;
const SignedBlock = state_transition.SignedBlock;
const Block = state_transition.Block;
const SignedBeaconBlock = state_transition.SignedBeaconBlock;
const BeaconBlock = state_transition.BeaconBlock;
