const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("../config.zig").ForkSeq;
const ssz = @import("consensus_types");
const AttesterSlashing = ssz.phase0.AttesterSlashing.Type;
const isSlashableAttestationData = @import("../utils/attestation.zig").isSlashableAttestationData;
const getAttesterSlashableIndices = @import("../utils/attestation.zig").getAttesterSlashableIndices;
const isValidIndexedAttestation = @import("./is_valid_indexed_attestation.zig").isValidIndexedAttestation;
const isSlashableValidator = @import("../utils/validator.zig").isSlashableValidator;
const slashValidator = @import("./slash_validator.zig").slashValidator;

pub fn processAttesterSlashing(fork: ForkSeq, cached_state: *CachedBeaconStateAllForks, attester_slashing: *const AttesterSlashing, verify_signature: ?bool) !void {
    const state = cached_state.state;
    const epoch = cached_state.epoch_cache.epoch;
    try assertValidAttesterSlashing(cached_state, attester_slashing, verify_signature);

    const intersecting_indices = try getAttesterSlashableIndices(cached_state.allocator, attester_slashing);
    defer intersecting_indices.deinit();

    var slashed_any: bool = false;
    // Spec requires to sort indices beforehand but we validated sorted asc AttesterSlashing in the above functions
    for (intersecting_indices.items) |validator_index| {
        const validator = state.getValidator(validator_index);
        if (isSlashableValidator(&validator, epoch)) {
            try slashValidator(fork, cached_state, validator_index, null);
            slashed_any = true;
        }
    }

    if (!slashed_any) {
        return error.InvalidAttesterSlashingNoSlashableValidators;
    }
}

pub fn assertValidAttesterSlashing(cached_state: *CachedBeaconStateAllForks, attester_slashing: *const AttesterSlashing, verify_signatures: ?bool) !void {
    const attestations = &.{ attester_slashing.attestation_1, attester_slashing.attestation_2 };
    if (!isSlashableAttestationData(&attestations[0].data, &attestations[1].data)) {
        return error.InvalidAttesterSlashingNotSlashable;
    }

    inline for (0..2) |i| {
        if (!try isValidIndexedAttestation(cached_state, attestations[i], verify_signatures)) {
            return error.InvalidAttesterSlashingAttestationInvalid;
        }
    }
}
