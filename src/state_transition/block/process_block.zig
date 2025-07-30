const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("params").ForkSeq;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const SignedBlock = @import("../state_transition.zig").SignedBlock;
const BlockExternalData = @import("external_data.zig").BlockExternalData;
const processBlobKzgCommitments = @import("./process_blob_kzg_commitments.zig").processBlobKzgCommitments;
const processBlockHeader = @import("./process_block_header.zig").processBlockHeader;
const processEth1Data = @import("./process_eth1_data.zig").processEth1Data;
const processExecutionPayload = @import("./process_execution_payload.zig").processExecutionPayload;
const processOperations = @import("./process_operations.zig").processOperations;
const processRandao = @import("./process_randao.zig").processRandao;
const processSyncAggregate = @import("./process_sync_committee.zig").processSyncAggregate;
const processWithdrawals = @import("./process_withdrawals.zig").processWithdrawals;
const ProcessBlockOpts = @import("./types.zig").ProcessBlockOpts;
const isExecutionEnabled = @import("../utils/execution.zig").isExecutionEnabled;
// TODO: proposer reward api
// const ProposerRewardType = @import("../types/proposer_reward.zig").ProposerRewardType;

// TODO
pub fn processBlock(
    allocator: Allocator,
    cached_state: *const CachedBeaconStateAllForks,
    // TODO: support BlindedBeaconBlock
    block: *const SignedBlock,
    external_data: BlockExternalData,
    opts: ?ProcessBlockOpts,
    // TODO: metrics
) !void {
    const state = cached_state.state;

    try processBlockHeader(allocator, cached_state, block);

    // The call to the process_execution_payload must happen before the call to the process_randao as the former depends
    // on the randao_mix computed with the reveal of the previous block.
    if (state.isPostBellatrix() and isExecutionEnabled(cached_state.state, block)) {
        // TODO Deneb: Allow to disable withdrawals for interop testing
        // https://github.com/ethereum/consensus-specs/blob/b62c9e877990242d63aa17a2a59a49bc649a2f2e/specs/eip4844/beacon-chain.md#disabling-withdrawals
        if (state.isPostCapella()) {
            try processWithdrawals(
                allocator,
                cached_state,
                &block.getBeaconBlockBody().getExecutionPayload(),
            );
        }

        switch (block) {
            .signed_beacon_block => |b| try processExecutionPayload(
                allocator,
                cached_state,
                b.getBeaconBlockBody(),
                external_data,
            ),
            .signed_blinded_beacon_block => |b| try processExecutionPayloadHeader(
                allocator,
                cached_state,
                b,
                external_data,
            ),
        }
        try processExecutionPayload();
    }

    try processRandao(state, block, opts.verify_signature);
    try processEth1Data(state, block.getBeaconBlockBody().getEth1Data());
    try processOperations(cached_state, block.getBeaconBlockBody(), external_data);
    if (state.isPostAltair()) {
        try processSyncAggregate(cached_state, block, opts.verify_signature);
    }

    if (state.isPostDeneb()) {
        try processBlobKzgCommitments(allocator, external_data);
        // Only throw PreData so beacon can also sync/process blocks optimistically
        // and let forkChoice handle it
        if (external_data.data_availability_status == .PreData) {
            return error.DataAvailabilityPreData;
        }
    }
}
