const std = @import("std");
const ForkSeq = @import("params").ForkSeq;
const ssz = @import("consensus_types");
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const SignedBlock = @import("../types/signed_block.zig").SignedBlock;
const BeaconBlockBody = @import("../types/beacon_block.zig").BeaconBlockBody;
const ExecutionPayload = @import("../types/beacon_block.zig").ExecutionPayload;
// const ExecutionPayloadHeader
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;

// TODO: support BlindedBeaconBlock
pub fn isExecutionEnabled(state: *const BeaconStateAllForks, block: *const SignedBlock) bool {
    if (!state.isPostBellatrix()) return false;
    if (isMergeTransitionComplete(state)) return true;

    // TODO(bing): in lodestar prod, state root comparison should be enough but spec tests were failing. This switch block is a failsafe for that.
    //
    // Ref: https://github.com/ChainSafe/lodestar/blob/7f2271a1e2506bf30378da98a0f548290441bdc5/packages/state-transition/src/util/execution.ts#L37-L42
    switch (block.*) {
        .blinded => |b| {
            const body = b.beaconBlock().beaconBlockBody();

            const ExecutionPayloadHeaderType = switch (body) {
                .capella => ssz.capella.ExecutionPayloadHeader,
                .deneb => ssz.deneb.ExecutionPayloadHeader,
                .electra => ssz.electra.ExecutionPayloadHeader,
            };
            return ExecutionPayloadHeaderType.equals(body.executionPayloadHeader(), ExecutionPayloadHeaderType.default_value);
        },
        .regular => |b| {
            const body = b.beaconBlock().beaconBlockBody();

            const ExecutionPayloadType = switch (body) {
                .bellatrix => ssz.bellatrix.ExecutionPayload,
                .capella => ssz.capella.ExecutionPayload,
                .deneb => ssz.deneb.ExecutionPayload,
                .electra => ssz.electra.ExecutionPayload,
            };

            return ExecutionPayloadType.equals(body.executionPayload(), ExecutionPayloadType.default_value);
        },
    }
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
    _ = state;
    return false;

    // std.debug.assert(state.forkSeq() == .bellatrix or state.forkSeq() == .capella);
    // TODO(bing): reenable below code when 'equals' works; first return false to test longer codepath

    // TODO(bing): Fix equals
    // if (!state.isPostCapella()) {
    //     return !ssz.bellatrix.ExecutionPayload.equals(state.latestExecutionPayloadHeader().bellatrix, ssz.bellatrix.ExecutionPayloadHeader.default_value);
    // }

    // return !ssz.capella.ExecutionPayload.equals(state.latestExecutionPayloadHeader().capella, ssz.capella.ExecutionPayloadHeader.default_value);
}
