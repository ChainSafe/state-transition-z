const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const SignedBeaconBlock = @import("../types/beacon_block.zig").SignedBeaconBlock;
const SingleSignatureSet = @import("../utils/signature_sets.zig").SingleSignatureSet;
const params = @import("params");
const ssz = @import("consensus_types");
const Root = ssz.primitive.Root;
const computeBlockSigningRoot = @import("../utils/signing_root.zig").computeBlockSigningRoot;
const computeSigningRoot = @import("../utils/signing_root.zig").computeSigningRoot;
const verifySignatureSet = @import("../utils/signature_sets.zig").verifySingleSignatureSet;

pub fn verifyProposerSignature(cached_state: *const CachedBeaconStateAllForks, signed_block: *const SignedBeaconBlock) bool {
    const signature_set = getBlockProposerSignatureSet(cached_state.allocator, cached_state, signed_block);
    return verifySignatureSet(signature_set);
}

// TODO: support SignedBlindedBeaconBlock
pub fn getBlockProposerSignatureSet(allocator: Allocator, cached_state: *const CachedBeaconStateAllForks, signed_block: *const SignedBeaconBlock) SingleSignatureSet {
    const config = cached_state.config;
    const state = cached_state.state;
    const epoch_cache = cached_state.getEpochCache();
    const domain = config.getDomain(state.getSlot(), params.DOMAIN_BEACON_PROPOSER, signed_block.getBeaconBlock().getSlot());
    var signing_root: Root = undefined;
    const beacon_block = signed_block.getBeaconBlock();
    try computeBlockSigningRoot(allocator, beacon_block, domain, &signing_root);

    return .{
        .pubkey = epoch_cache.index_to_pubkey(beacon_block.getProposerIndex()),
        .signing_root = signing_root,
        .signature = signed_block.getSignature(),
    };
}

pub fn getBlockHeaderProposerSignatureSet(cached_state: *const CachedBeaconStateAllForks, signed_block_header: *const ssz.phase0.SignedBeaconBlockHeader.Type) SingleSignatureSet {
    const config = cached_state.config;
    const state = cached_state.state;
    const epoch_cache = cached_state.getEpochCache();

    const domain = config.getDomain(state.getSlot(), params.DOMAIN_BEACON_PROPOSER, signed_block_header.message.slot);
    var signing_root: Root = undefined;
    try computeSigningRoot(ssz.phase0.SignedBeaconBlockHeader, signed_block_header, domain, &signing_root);

    return .{
        .pubkey = epoch_cache.index_to_pubkey(signed_block_header.message.proposerIndex),
        .signing_root = signing_root,
        .signature = signed_block_header.signature,
    };
}
