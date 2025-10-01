const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("config").ForkSeq;
const ssz = @import("consensus_types");
const AttesterSlashing = ssz.phase0.AttesterSlashing.Type;
const isSlashableAttestationData = @import("../utils/attestation.zig").isSlashableAttestationData;
const getAttesterSlashableIndices = @import("../utils/attestation.zig").getAttesterSlashableIndices;
const isValidIndexedAttestation = @import("./is_valid_indexed_attestation.zig").isValidIndexedAttestation;
const isSlashableValidator = @import("../utils/validator.zig").isSlashableValidator;
const slashValidator = @import("./slash_validator.zig").slashValidator;

/// AS is the AttesterSlashing type
/// - for phase0 it is `ssz.phase0.AttesterSlashing.Type`
/// - for electra it is `ssz.electra.AttesterSlashing.Type`
pub fn processAttesterSlashing(comptime AS: type, allocator: std.mem.Allocator, cached_state: *const CachedBeaconStateAllForks, attester_slashing: *const AS, verify_signature: ?bool) !void {
    const state = cached_state.state;
    const epoch = cached_state.getEpochCache().epoch;
    try assertValidAttesterSlashing(AS, allocator, cached_state, attester_slashing, verify_signature);

    const intersecting_indices = try getAttesterSlashableIndices(cached_state.allocator, attester_slashing);
    defer intersecting_indices.deinit();

    var slashed_any: bool = false;
    // Spec requires to sort indices beforehand but we validated sorted asc AttesterSlashing in the above functions
    for (intersecting_indices.items) |validator_index| {
        const validator = state.validators().items[validator_index];
        if (isSlashableValidator(&validator, epoch)) {
            try slashValidator(cached_state, validator_index, null);
            slashed_any = true;
        }
    }

    if (!slashed_any) {
        return error.InvalidAttesterSlashingNoSlashableValidators;
    }
}

/// AS is the AttesterSlashing type
/// - for phase0 it is `ssz.phase0.AttesterSlashing.Type`
/// - for electra it is `ssz.electra.AttesterSlashing.Type`
pub fn assertValidAttesterSlashing(comptime AS: type, allocator: std.mem.Allocator, cached_state: *const CachedBeaconStateAllForks, attester_slashing: *const AS, verify_signatures: ?bool) !void {
    const attestations = &.{ attester_slashing.attestation_1, attester_slashing.attestation_2 };
    if (!isSlashableAttestationData(&attestations[0].data, &attestations[1].data)) {
        return error.InvalidAttesterSlashingNotSlashable;
    }

    inline for (@typeInfo(AS).@"struct".fields, 0..2) |f, i| {
        if (!try isValidIndexedAttestation(f.type, allocator, cached_state, &attestations[i], verify_signatures)) {
            return error.InvalidAttesterSlashingAttestationInvalid;
        }
    }
}
