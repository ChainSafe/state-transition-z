const std = @import("std");
const Allocator = std.mem.Allocator;
const blst = @import("blst_min_pk");
const PublicKey = blst.PublicKey;
const ssz = @import("consensus_types");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;
const params = @import("../params.zig");
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
pub fn getAttestationWithIndicesSignatureSet(allocator: Allocator, cached_state: *const CachedBeaconStateAllForks, data: *const AttestationData, signature: BLSSignature, attesting_indices: []usize) !AggregatedSignatureSet {
    const epoch_cache = cached_state.epoch_cache;

    const pubkeys = try allocator.alloc(*const PublicKey, attesting_indices.len);
    for (0..attesting_indices.len) |i| {
        pubkeys[i] = epoch_cache.index_to_pubkey[attesting_indices[i]];
    }

    const signing_root: Root = undefined;
    try getAttestationDataSigningRoot(cached_state, data, &signing_root);

    return createAggregateSignatureSetFromComponents(pubkeys, signing_root, signature);
}

pub fn getIndexedAttestationSignatureSet(allocator: Allocator, cached_state: *const CachedBeaconStateAllForks, indexed_attestation: *const IndexedAttestation) !AggregatedSignatureSet {
    return try getAttestationWithIndicesSignatureSet(allocator, cached_state, &indexed_attestation.data, indexed_attestation.signature, indexed_attestation.attesting_indices);
}

// TODO: implement getIndexedAttestation in EpochCache
// export function getAttestationsSignatureSets(
//   state: CachedBeaconStateAllForks,
//   signedBlock: SignedBeaconBlock
// ): ISignatureSet[] {
//   // TODO: figure how to get attesting indices of an attestation once per block processing
//   return signedBlock.message.body.attestations.map((attestation) =>
//     getIndexedAttestationSignatureSet(
//       state,
//       state.epochCtx.getIndexedAttestation(state.config.getForkSeq(signedBlock.message.slot), attestation)
//     )
//   );
// }
