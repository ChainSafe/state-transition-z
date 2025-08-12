const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const SignedBeaconBlock = @import("../types/beacon_block.zig").SignedBeaconBlock;
const SingleSignatureSet = @import("../utils/signature_sets.zig").SingleSignatureSet;
const AggregatedSignatureSet = @import("../utils/signature_sets.zig").AggregatedSignatureSet;
const params = @import("params");
const ssz = @import("consensus_types");
const Root = ssz.primitive.Root.Type;
const blst = @import("blst_min_pk");
const computeBlockSigningRoot = @import("../utils/signing_root.zig").computeBlockSigningRoot;
const computeSigningRoot = @import("../utils/signing_root.zig").computeSigningRoot;
const verifySignatureSet = @import("../utils/signature_sets.zig").verifySingleSignatureSet;
const computeStartSlotAtEpoch = @import("../utils/epoch.zig").computeStartSlotAtEpoch;
const IndexedAttestation = @import("../types/attestation.zig").IndexedAttestation;

pub fn getAttesterSlashingsSignatureSets(
    allocator: Allocator,
    cached_state: *const CachedBeaconStateAllForks,
    signed_block: *const SignedBeaconBlock,
    out: *std.ArrayList(AggregatedSignatureSet),
) !void {
    const attester_slashings = signed_block.getBeaconBlock().getBeaconBlockBody().getAttesterSlashings();
    switch (attester_slashings) {
        .electra => |as| {
            for (as.items) |ia| {
                try getIndexedAttestationSignatureSet(ssz.electra.IndexedAttestation.Type, allocator, cached_state, &ia.attestation_1, out);
                try getIndexedAttestationSignatureSet(ssz.electra.IndexedAttestation.Type, allocator, cached_state, &ia.attestation_2, out);
            }
        },
        .phase0 => |as| {
            for (as.items) |ia| {
                try getIndexedAttestationSignatureSet(ssz.phase0.IndexedAttestation.Type, allocator, cached_state, &ia.attestation_1, out);
                try getIndexedAttestationSignatureSet(ssz.phase0.IndexedAttestation.Type, allocator, cached_state, &ia.attestation_2, out);
            }
        },
    }
}

pub fn getIndexedAttestationSignatureSet(
    comptime T: type,
    allocator: Allocator,
    cached_state: *const CachedBeaconStateAllForks,
    indexed_attestation: *const T,
    out: *std.ArrayList(AggregatedSignatureSet),
) !void {
    const slot = computeStartSlotAtEpoch(indexed_attestation.data.target.epoch);
    const domain = try cached_state.config.getDomain(cached_state.state.getSlot(), params.DOMAIN_BEACON_ATTESTER, slot);
    var root: Root = undefined;
    try computeSigningRoot(ssz.phase0.AttestationData, &indexed_attestation.data, domain, &root);

    const epoch_cache = cached_state.getEpochCache();
    const pubkeys = try allocator.alloc(*const blst.PublicKey, indexed_attestation.attesting_indices.items.len);

    for (0..indexed_attestation.attesting_indices.items.len) |i| {
        pubkeys[i] = epoch_cache.index_to_pubkey.items[i];
    }
    try out.append(.{
        .pubkeys = pubkeys,
        .signing_root = root,
        .signature = indexed_attestation.signature,
    });
}
