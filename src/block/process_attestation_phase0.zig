const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const ForkSeq = @import("../types/fork.zig").ForkSeq;
const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;
const isValidIndexedAttestation = @import("./is_valid_indexed_attestation.zig").isValidIndexedAttestation;
const Slot = ssz.primitive.Slot.Type;
const Checkpoint = ssz.phase0.Checkpoint.Type;
const Phase0Attestation = ssz.phase0.Attestation.Type;
const ElectraAttestation = ssz.electra.Attestation.Type;
const PendingAttestation = ssz.phase0.PendingAttestation.Type;

pub fn processAttestationPhase0(cached_state: *CachedBeaconStateAllForks, attestation: *const Phase0Attestation, verify_signature: ?bool) void {
    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;
    const slot = state.getSlot();
    const data = attestation.data;

    try validateAttestation(Phase0Attestation, cached_state, attestation);

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

/// AT could be either Phase0Attestation or ElectraAttestation
pub fn validateAttestation(comptime AT: type, cached_state: *const CachedBeaconStateAllForks, attestation: AT) !void {
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
    if (!(data.slot + preset.MIN_ATTESTATION_INCLUSION_DELAY <= slot and isTimelyTarget(state, slot - data.slot))) {
        return error.InvalidAttestationSlotNotWithInInclusionWindow;
    }

    // same to fork >= ForkSeq.electra but more type safe
    if (AT == ElectraAttestation) {
        if (data.index != 0) {
            return error.InvalidAttestationNonZeroDataIndex;
        }
        // TODO(ssz): implement getTrueBitIndexes() api
        const committee_indices = attestation.committee_bits.getTrueBitIndexes();
        if (committee_indices.items.len == 0) {
            return error.InvalidAttestationCommitteeBitsEmpty;
        }

        const last_committee_index = committee_indices.items[committee_indices.items.len - 1];

        if (last_committee_index >= committee_count) {
            return error.InvalidAttestationInvalidLstCommitteeIndex;
        }

        // const validators_by_committee = try epoch_cache.getBeaconCommittees(slot, committee_indices.items);
        // TODO(ssz): implement toBoolArray() for BitVector/BitList https://github.com/ChainSafe/ssz-z/issues/25
        const aggregation_bits_array = attestation.aggregation_bits.toBoolArray().items;
        // instead of implementing/calling getBeaconCommittees(slot, committee_indices.items), we call getBeaconCommittee(slot, index)
        var committee_offset: usize = 0;
        for (committee_indices.items) |committee_index| {
            const committee_validators = try epoch_cache.getBeaconCommittee(slot, committee_index);
            const committee_aggregation_bits = aggregation_bits_array[committee_offset..(committee_offset + committee_validators.len)];

            // Assert aggregation bits in this committee have at least one true bit
            var all_false: bool = true;
            for (committee_aggregation_bits) |bit| {
                if (bit == true) {
                    all_false = false;
                    break;
                }
            }

            if (all_false) {
                return error.InvalidAttestationCommitteeAggregationBitsAllFalse;
            }
            committee_offset += committee_validators.len;
        }

        if (attestation.aggregation_bits.bit_len != committee_offset) {
            return error.InvalidAttestationCommitteeAggregationBitsLengthMismatch;
        }
    } else {
        // specific logic of phase to deneb
        if (!(data.index < committee_count)) {
            return error.InvalidAttestationInvalidCommitteeIndex;
        }

        const committee = try epoch_cache.getBeaconCommittee(slot, data.index);
        if (attestation.aggregation_bits.bit_len != committee.len) {
            return error.InvalidAttestationInvalidAggregationBitLen;
        }
    }
}

pub fn isTimelyTarget(state: *const BeaconStateAllForks, inclusion_distance: Slot) bool {
    // post deneb attestation is valid till end of next epoch for target
    if (state.isPostDeneb()) {
        return true;
    }

    return inclusion_distance <= preset.SLOTS_PER_EPOCH;
}
