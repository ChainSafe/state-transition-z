const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const BeaconConfig = @import("../config.zig").BeaconConfig;
const BeaconBlockHeader = @import("../type.zig").BeaconBlockHeader;
const Root = @import("../type.zig").Root;
const ZERO_HASH = @import("../constants.zig").ZERO_HASH;

// TODO: BlindedBeaconBlock
pub fn processBlockHeader(allocator: Allocator, cached_state: *CachedBeaconStateAllForks, block: *const BeaconBlock) !void {
    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;
    const slot = state.getSlot();

    // verify that the slots match
    if (block.getSlot() != slot) {
        return error.BlockSlotMismatch;
    }

    // Verify that the block is newer than latest block header
    if (!(block.getSlot() > state.getLatestBlockHeader().slot)) {
        return error.BlockNotNewerThanLatestHeader;
    }

    // verify that proposer index is the correct index
    const proposer_index = epoch_cache.getBeaconProposer(slot);
    if (block.getProposerIndex() != proposer_index) {
        return error.BlockProposerIndexMismatch;
    }

    // verify that the parent matches
    if (!std.mem.eql(u8, &block.getParentRoot(), &ssz.phase0.BeaconBlockHeader.hashTreeRoot(state.getLatestBlockHeader()))) {
        return error.BlockParentRootMismatch;
    }

    var block_header: BeaconBlockHeader = undefined;
    try blockToHeader(allocator, block, &block_header);

    // cache current block as the new latest block
    state.setLatestBlockHeader(&.{
        .slot = slot,
        .proposer_index = proposer_index,
        .parent_root = block.getParentRoot(),
        .state_root = ZERO_HASH,
        .bodyRoot = block_header.body_root,
    });

    // verify proposer is not slashed. Only once per block, may use the slower read from tree
    if (state.getValidator(proposer_index).slashed) {
        return error.BlockProposerSlashed;
    }
}

pub fn blockToHeader(allocator: Allocator, block: *const BeaconBlock, out: *BeaconBlockHeader) !void {
    out.slot = block.getSlot();
    out.proposer_index = block.getProposerIndex();
    out.parent_root = block.getParentRoot();
    out.state_root = block.getStateRoot();
    try block.getBeaconBlockBody().hashTreeRoot(allocator, &out.bodyRoot);
}
