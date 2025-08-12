const std = @import("std");
const Allocator = std.mem.Allocator;
const blst = @import("blst_min_pk");
const PublicKey = blst.PublicKey;
const ssz = @import("consensus_types");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const SignedBeaconBlock = @import("../types/beacon_block.zig").SignedBeaconBlock;
const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;
const params = @import("params");
const computeSigningRoot = @import("../utils/signing_root.zig").computeSigningRoot;
const types = @import("../type.zig");
const AttestationData = types.AttestationData;
const Attestation = types.Attestation;
const BLSSignature = types.BLSSignature;
const Root = types.Root;
const AggregatedSignatureSet = @import("../utils/signature_sets.zig").AggregatedSignatureSet;
const createAggregateSignatureSetFromComponents = @import("../utils/signature_sets.zig").createAggregateSignatureSetFromComponents;
const IndexedAttestation = @import("../types/attestation.zig").IndexedAttestation;

pub fn getAttestationDataSigningRoot(cached_state: *const CachedBeaconStateAllForks, data: *const AttestationData, out: *[32]u8) !void {
    const slot = computeEpochAtSlot(data.target.epoch);
    const config = cached_state.config;
    const state = cached_state.state;
    const domain = try config.getDomain(state.getSlot(), params.DOMAIN_BEACON_ATTESTER, slot);

    try computeSigningRoot(ssz.phase0.AttestationData, data, domain, out);
}

/// Consumer need to free the returned pubkeys array
pub fn getAttestationWithIndicesSignatureSet(
    allocator: Allocator,
    cached_state: *const CachedBeaconStateAllForks,
    data: *const AttestationData,
    signature: BLSSignature,
    attesting_indices: []u64,
) !AggregatedSignatureSet {
    const epoch_cache = cached_state.getEpochCache();

    const pubkeys = try allocator.alloc(*const PublicKey, attesting_indices.len);
    for (0..attesting_indices.len) |i| {
        pubkeys[i] = epoch_cache.index_to_pubkey.items[@intCast(attesting_indices[i])];
    }

    var signing_root: Root = undefined;
    try getAttestationDataSigningRoot(cached_state, data, &signing_root);

    return .{ .pubkeys = pubkeys, .signing_root = signing_root, .signature = signature };
}

pub fn getIndexedAttestationSignatureSet(comptime IA: type, allocator: Allocator, cached_state: *const CachedBeaconStateAllForks, indexed_attestation: *const IA) !AggregatedSignatureSet {
    return try getAttestationWithIndicesSignatureSet(allocator, cached_state, &indexed_attestation.data, indexed_attestation.signature, indexed_attestation.attesting_indices.items);
}

pub fn getAttestationsSignatureSets(allocator: Allocator, cached_state: *const CachedBeaconStateAllForks, signed_block: *const SignedBeaconBlock, out: *std.ArrayList(AggregatedSignatureSet)) !void {
    const epoch_cache = cached_state.getEpochCache();
    const attestation_items = signed_block.getBeaconBlock().getBeaconBlockBody().getAttestations().items();

    switch (attestation_items) {
        .phase0 => |phase0_attestations| {
            for (phase0_attestations) |attestation| {
                const indexed_attestation = try epoch_cache.getIndexedAttestation(.{ .phase0 = attestation });
                const signature_set = try getIndexedAttestationSignatureSet(ssz.phase0.IndexedAttestation.Type, allocator, cached_state, &indexed_attestation.phase0.*);
                try out.append(signature_set);
            }
        },
        .electra => |electra_attestations| {
            for (electra_attestations) |attestation| {
                const indexed_attestation = try epoch_cache.getIndexedAttestation(.{ .electra = attestation });
                const signature_set = try getIndexedAttestationSignatureSet(ssz.electra.IndexedAttestation.Type, allocator, cached_state, &indexed_attestation.electra.*);
                try out.append(signature_set);
            }
        },
    }
}
