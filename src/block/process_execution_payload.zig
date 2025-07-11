const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const params = @import("../params.zig");
const ForkSeq = @import("../config.zig").ForkSeq;
const BeaconBlockBody = @import("../types/beacon_block.zig").BeaconBlockBody;
const ExecutionPayloadStatus = @import("./external_data.zig").ExecutionPayloadStatus;
const BeaconConfig = @import("../config.zig").BeaconConfig;
const isMergeTransitionComplete = @import("../utils/execution.zig").isMergeTransitionComplete;
const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;
const getRandaoMix = @import("../utils/seed.zig").getRandaoMix;

// TODO: support BlindedBeaconBlockBody
pub fn processExecutionPayload(allocator: Allocator, cached_state: *CachedBeaconStateAllForks, body: BeaconBlockBody, external_data: ExecutionPayloadStatus) !void {
    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;
    const config = epoch_cache.config;
    const payload = body.getExecutionPayload();
    // Verify consistency of the parent hash, block number, base fee per gas and gas limit
    // with respect to the previous execution payload header
    if (isMergeTransitionComplete(state)) {
        const execution_payload_header = state.getLatestExecutionPayloadHeader();
        if (!std.mem.eql(u8, &payload.getParentHash(), &execution_payload_header.getBlockHash())) {
            return error.InvalidExecutionPayloadParentHash;
        }
    }

    // Verify random
    const expected_random = getRandaoMix(state.*, epoch_cache.epoch);
    if (!std.mem.eql(u8, &payload.getPrevRandao(), &expected_random)) {
        return error.InvalidExecutionPayloadRandom;
    }

    // Verify timestamp
    //
    // Note: inlined function in if statement
    // def compute_timestamp_at_slot(state: BeaconState, slot: Slot) -> uint64:
    //   slots_since_genesis = slot - GENESIS_SLOT
    //   return uint64(state.genesis_time + slots_since_genesis * SECONDS_PER_SLOT)
    if (payload.getTimestamp() != state.getGenesisTime() + state.getSlot() * config.chain.SECONDS_PER_SLOT) {
        return error.InvalidExecutionPayloadTimestamp;
    }

    if (state.isPostDeneb()) {
        const max_blobs_per_block = config.getMaxBlobsPerBlock(computeEpochAtSlot(state.getSlot()));
        const blob_kzg_commitments_len = body.getBlobKzgCommitments().items.len;
        if (blob_kzg_commitments_len > max_blobs_per_block) {
            return error.BlobKzgCommitmentsExceedsLimit;
        }
    }

    // Verify the execution payload is valid
    //
    // if executionEngine is null, executionEngine.onPayload MUST be called after running processBlock to get the
    // correct randao mix. Since executionEngine will be an async call in most cases it is called afterwards to keep
    // the state transition sync
    //
    // Equivalent to `assert executionEngine.notifyNewPayload(payload)
    if (external_data == ExecutionPayloadStatus.pre_merge) {
        return error.ExecutionPayloadStatusPreMerge;
    } else if (external_data == ExecutionPayloadStatus.invalid) {
        return error.InvalidExecutionPayload;
    }

    const payload_header = try payload.toPayloadHeader(allocator);
    state.setLatestExecutionPayloadHeader(payload_header);
}
