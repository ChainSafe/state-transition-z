const ForkSeq = @import("../config.zig").ForkSeq;
const ssz = @import("consensus_types");
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const BeaconBlockBody = @import("../types/beacon_block.zig").BeaconBlockBody;
const ExecutionPayload = @import("../types/beacon_block.zig").ExecutionPayload;
// const ExecutionPayloadHeader
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;

// TODO: support BlindedBeaconBlock
pub fn isExecutionEnabled(state: *const BeaconStateAllForks, block: *const BeaconBlock) bool {
    if (!state.isPostBellatrix()) {
        return false;
    }

    if (isMergeTransitionComplete(state)) {
        return true;
    }

    const payload = block.getBeaconBlockBody().getExecutionPayload();

    return (state.isBellatrix() and ssz.bellatrix.ExecutionPayload.equals(payload.bellatrix, ssz.bellatrix.ExecutionPayload.default_value));
}

pub fn isMergeTransitionBlock(state: *const BeaconStateAllForks, body: *const BeaconBlockBody) bool {
    if (!state.isBellatrix()) {
        return false;
    }

    return (!isMergeTransitionComplete(state) and
        !ssz.bellatrix.ExecutionPayload.equals(body.getExecutionPayload().bellatrix, ssz.bellatrix.ExecutionPayload.default_value));
}

// TODO: make sure this function is not called for forks other than Bellatrix and Capella
pub fn isMergeTransitionComplete(state: *const BeaconStateAllForks) bool {
    if (!state.isPostCapella()) {
        return !ssz.bellatrix.ExecutionPayload.equals(state.getLatestExecutionPayloadHeader().bellatrix, ssz.bellatrix.ExecutionPayloadHeader.default_value);
    }

    return !ssz.capella.ExecutionPayload.equals(state.getLatestExecutionPayloadHeader().capella, ssz.capella.ExecutionPayloadHeader.default_value);
}
