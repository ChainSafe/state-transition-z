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

pub fn getProposerSlashingSignatureSets(cached_state: *const CachedBeaconStateAllForks, proposer_slashing: *const ssz.phase0.ProposerSlashing.Type) ![2]SingleSignatureSet {
    const config = cached_state.config;
    const state = cached_state.state;
    const epoch_cache = cached_state.getEpochCache();

    const signed_header_1 = proposer_slashing.signed_header_1;
    const signed_header_2 = proposer_slashing.signed_header_2;
    // In state transition, ProposerSlashing headers are only partially validated. Their slot could be higher than the
    // clock and the slashing would still be valid. Must use bigint variants to hash correctly to all possible values
    var result: [2]SingleSignatureSet = undefined;
    const domain_1 = try config.getDomain(state.slot(), params.DOMAIN_BEACON_PROPOSER, signed_header_1.message.slot);
    const domain_2 = try config.getDomain(state.slot(), params.DOMAIN_BEACON_PROPOSER, signed_header_2.message.slot);
    var signing_root_1: [32]u8 = undefined;
    try computeSigningRoot(ssz.phase0.SignedBeaconBlockHeader, &signed_header_1, domain_1, &signing_root_1);
    var signing_root_2: [32]u8 = undefined;
    try computeSigningRoot(ssz.phase0.SignedBeaconBlockHeader, &signed_header_2, domain_2, &signing_root_2);

    result[0] = SingleSignatureSet{
        .pubkey = epoch_cache.index_to_pubkey.items[signed_header_1.message.proposer_index].*,
        .signing_root = signing_root_1,
        .signature = signed_header_1.signature,
    };

    result[1] = SingleSignatureSet{
        .pubkey = epoch_cache.index_to_pubkey.items[signed_header_2.message.proposer_index].*,
        .signing_root = signing_root_2,
        .signature = signed_header_2.signature,
    };

    return result;
}

pub fn getProposerSlashingsSignatureSets(cached_state: *const CachedBeaconStateAllForks, signed_block: *const SignedBeaconBlock, out: std.ArrayList(SingleSignatureSet)) !void {
    const proposer_slashings = signed_block.getBeaconBlock().getBeaconBlockBody().getProposerSlashings().items;
    for (proposer_slashings) |proposer_slashing| {
        const signature_sets = getProposerSlashingSignatureSets(cached_state, proposer_slashing);
        try out.append(signature_sets[0]);
        try out.append(signature_sets[1]);
    }
}
