const std = @import("std");
const ssz = @import("consensus_types");
const Slot = ssz.primitive.Slot.Type;
const types = @import("../type.zig");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const Root = types.Root;
const BeaconBlockBody_ = @import("../signed_block.zig").SignedBlock.BeaconBlockBody_;
const SingleSignatureSet = @import("../utils/signature_sets.zig").SingleSignatureSet;
const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;
const params = @import("params");
const computeSigningRoot = @import("../utils/signing_root.zig").computeSigningRoot;
const verifySingleSignatureSet = @import("../utils/signature_sets.zig").verifySingleSignatureSet;

pub fn verifyRandaoSignature(
    state: *const CachedBeaconStateAllForks,
    body: *const BeaconBlockBody_,
    slot: Slot,
    proposer_idx: u64,
) !bool {
    const signature_set = try getRandaoRevealSignatureSet(state, body, slot, proposer_idx);
    return verifySingleSignatureSet(&signature_set);
}

pub fn getRandaoRevealSignatureSet(
    cached_state: *const CachedBeaconStateAllForks,
    body: *const BeaconBlockBody_,
    slot: Slot,
    proposer_idx: u64,
) !SingleSignatureSet {
    const epoch_cache = cached_state.getEpochCache();
    const state = cached_state.state;
    const config = cached_state.config;

    // should not get epoch from epoch_cache
    const epoch = computeEpochAtSlot(slot);
    const domain = try config.getDomain(state.getSlot(), params.DOMAIN_RANDAO, slot);
    var signing_root: Root = undefined;
    try computeSigningRoot(ssz.primitive.Epoch, &epoch, domain, &signing_root);
    return .{
        .pubkey = epoch_cache.index_to_pubkey.items[proposer_idx].*,
        .signing_root = signing_root,
        .signature = body.*.regular.getRandaoReveal(),
    };
}
