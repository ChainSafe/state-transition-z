const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const ForkSeq = @import("../config.zig").ForkSeq;
const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;
const isValidIndexedAttestation = @import("./is_valid_indexed_attestation.zig").isValidIndexedAttestation;
const Slot = ssz.primitive.Slot.Type;
const Checkpoint = ssz.phase0.Checkpoint.Type;
const Phase0Attestation = ssz.phase0.Attestation.Type;
const PendingAttestation = ssz.phase0.PendingAttestation.Type;

pub fn processAttestationPhase0(cached_state: *CachedBeaconStateAllForks, attestation: *const Phase0Attestation, verify_signature: ?bool) void {
    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;
    const slot = state.getSlot();
    const data = attestation.data;

    try validateAttestationPreElectra(ForkSeq.phase0, cached_state, attestation);

    const pending_attestation = PendingAttestation{
        .data = data,
        .aggregation_bits = attestation.aggregation_bits,
        .inclusion_delay = slot - data.slot,
        .proposer_index = epoch_cache.getBeaconProposer(slot),
    };

    if (data.target.epoch == epoch_cache.epoch) {
        if (!ssz.phase0.Checkpoint.equals(data.source, state.getCurrentJustifiedCheckpoint())) {
            return error.InvalidAttestationSourceNotEqualToCurrentJustifiedCheckpoint;
        }
        state.addCurrentEpochPendingAttestation(pending_attestation);
    } else {
        if (!ssz.phase0.Checkpoint.equals(data.source, state.getPreviousJustifiedCheckpoint())) {
            return error.InvalidAttestationSourceNotEqualToPreviousJustifiedCheckpoint;
        }
        state.addPreviousEpochPendingAttestation(pending_attestation);
    }

    const indexed_attestation = try epoch_cache.getIndexedAttestation(&.{
        .phase0 = attestation.*,
    });

    try isValidIndexedAttestation(cached_state, &indexed_attestation, verify_signature);
}

pub fn validateAttestationPreElectra(fork: ForkSeq, cached_state: *const CachedBeaconStateAllForks, attestation: Phase0Attestation) !void {
    const epoch_cache = cached_state.epoch_cache;
    const state = cached_state.state;
    const slot = state.getSlot();
    const data = attestation.data;
    const computed_epoch = computeEpochAtSlot(data.slot);
    const committee_count = try epoch_cache.getCommitteeCountPerSlot(computed_epoch);
    if (data.target.epoch != epoch_cache.previous_shuffling.epoch and data.target.epoch != epoch_cache.epoch) {
        // TODO: print to stderr?
        return error.InvalidAttestationTargetEpochNotInPreviousOrCurrentEpoch;
    }

    if (data.target.epoch != computed_epoch) {
        return error.InvalidAttestationTargetEpochDoesNotMatchComputedEpoch;
    }

    // post deneb, the attestations are valid till end of next epoch
    if (!(data.slot + preset.MIN_ATTESTATION_INCLUSION_DELAY <= slot and isTimelyTarget(fork, slot - data.slot))) {
        return error.InvalidAttestationSlotNotWithInInclusionWindow;
    }

    // specific logic of phase to deneb
    if (!(data.index < committee_count)) {
        return error.InvalidAttestationInvalidCommitteeIndex;
    }

    const committee = try epoch_cache.getBeaconCommittee(slot, data.index);
    if (attestation.aggregation_bits.bit_len != committee.len) {
        return error.InvalidAttestationInvalidAggregationBitLen;
    }
}

pub fn isTimelyTarget(fork: ForkSeq, inclusion_distance: Slot) bool {
    // post deneb attestation is valid till end of next epoch for target
    if (fork >= ForkSeq.deneb) {
        return true;
    }

    return inclusion_distance <= preset.SLOTS_PER_EPOCH;
}
