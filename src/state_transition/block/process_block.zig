const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("params").ForkSeq;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const SignedBlock = @import("../types/signed_block.zig").SignedBlock;
const BlockExternalData = @import("../state_transition.zig").BlockExternalData;
const processBlobKzgCommitments = @import("./process_blob_kzg_commitments.zig").processBlobKzgCommitments;
const processBlockHeader = @import("./process_block_header.zig").processBlockHeader;
const processEth1Data = @import("./process_eth1_data.zig").processEth1Data;
const processExecutionPayload = @import("./process_execution_payload.zig").processExecutionPayload;
const processOperations = @import("./process_operations.zig").processOperations;
const processRandao = @import("./process_randao.zig").processRandao;
const processSyncAggregate = @import("./process_sync_committee.zig").processSyncAggregate;
const processWithdrawals = @import("./process_withdrawals.zig").processWithdrawals;
const getExpectedWithdrawals = @import("./process_withdrawals.zig").getExpectedWithdrawals;
const isExecutionEnabled = @import("../utils/execution.zig").isExecutionEnabled;
// TODO: proposer reward api
// const ProposerRewardType = @import("../types/proposer_reward.zig").ProposerRewardType;

pub const ProcessBlockOpts = struct {
    verify_signature: bool = true,
};

pub fn processBlock(
    allocator: Allocator,
    cached_state: *CachedBeaconStateAllForks,
    block: *const SignedBlock,
    external_data: BlockExternalData,
    opts: ProcessBlockOpts,
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
            var expected_withdrawals_result = try getExpectedWithdrawals(allocator, cached_state);
            // TODO(bing): do not deinit; simply clearRetainingCapacity because we will reuse the allocated slice anyway.
            defer expected_withdrawals_result.deinit(allocator);
            const body = block.beaconBlockBody();
            switch (body) {
                .regular => |b| {
                    const actual_withdrawals = b.executionPayload().getWithdrawals();
                    std.debug.assert(expected_withdrawals_result.withdrawals.items.len == actual_withdrawals.items.len);
                    for (expected_withdrawals_result.withdrawals.items, actual_withdrawals.items) |expected, actual| {
                        std.debug.assert(ssz.capella.Withdrawal.equals(&expected, &actual));
                    }
                },
                .blinded => |b| {
                    const header = b.executionPayloadHeader();
                    var expected: [32]u8 = undefined;
                    try ssz.capella.Withdrawals.hashTreeRoot(allocator, &expected_withdrawals_result.withdrawals, &expected);
                    var actual = header.getWithdrawalsRoot();
                    std.debug.assert(std.mem.eql(u8, &expected, &actual));
                },
            }
            try processWithdrawals(cached_state, expected_withdrawals_result);
        }

        try processExecutionPayload(
            allocator,
            cached_state,
            block.beaconBlockBody(),
            external_data,
        );
    }

    try processRandao(cached_state, &block.beaconBlockBody(), block.proposerIndex(), opts.verify_signature);
    try processEth1Data(allocator, cached_state, block.beaconBlockBody().eth1Data());
    try processOperations(allocator, cached_state, &block.beaconBlockBody(), opts);
    if (state.isPostAltair()) {
        try processSyncAggregate(allocator, cached_state, block, opts.verify_signature);
    }

    if (state.isPostDeneb()) {
        try processBlobKzgCommitments(external_data);
        // Only throw PreData so beacon can also sync/process blocks optimistically
        // and let forkChoice handle it
        if (external_data.data_availability_status == .pre_data) {
            return error.DataAvailabilityPreData;
        }
    }
}
