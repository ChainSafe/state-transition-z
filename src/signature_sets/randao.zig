const ssz = @import("consensus_types");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const SingleSignatureSet = @import("../utils/signature_sets.zig").SingleSignatureSet;
const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;
const params = @import("../params.zig");
const computeSigningRoot = @import("../utils/signing_root.zig").computeSigningRoot;
const verifySingleSignatureSet = @import("../utils/signature_sets.zig").verifySingleSignatureSet;

pub fn verifyRandaoSignature(state: *const CachedBeaconStateAllForks, block: *const BeaconBlock) bool {
    const signature_set = getRandaoRevealSignatureSet(state, block);
    return verifySingleSignatureSet(&signature_set);
}

pub fn getRandaoRevealSignatureSet(cached_state: *const CachedBeaconStateAllForks, block: *const BeaconBlock) SingleSignatureSet {
    const epoch_cache = cached_state.epoch_cache;
    const state = cached_state.state;
    const config = cached_state.config;

    // should not get epoch from epoch_cache
    const epoch = computeEpochAtSlot(block.slot);
    const domain = config.getDomain(state.getSlot(), params.DOMAIN_RANDAO, block.getSlot());

    return .{
        .pubkey = epoch_cache.index2pubkey[block.getProposerIndex()],
        .signing_root = computeSigningRoot(ssz.primitive.Epoch, epoch, domain),
        .signature = block.getBeaconBlockBody().getRandaoReveal(),
    };
}
