const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const AttestationData = ssz.phase0.AttestationData.Type;
const AttesterSlashing = ssz.phase0.AttesterSlashing.Type;
const primitives = @import("../types/primitives.zig");

const ValidatorIndex = primitives.ValidatorIndex;
const Slot = primitives.Slot;

pub fn isSlashableAttestationData(data1: *const AttestationData, data2: *const AttestationData) bool {
    // Double vote
    // TODO(bing): implement equals API. For now return skip
    // if (!ssz.phase0.AttestationData.equals(data1, data2) and data1.target.epoch == data2.target.epoch) {
    //     return true;
    // }
    // Surround vote
    if (data1.source.epoch < data2.source.epoch and data2.target.epoch < data1.target.epoch) {
        return true;
    }
    return false;
}

pub fn isValidAttestationSlot(attestation_slot: Slot, current_slot: Slot) bool {
    return attestation_slot + preset.MIN_ATTESTATION_INCLUSION_DELAY <= current_slot and
        current_slot <= attestation_slot + preset.SLOTS_PER_EPOCH;
}

// consumer takes the ownership of the returned array
pub fn getAttesterSlashableIndices(allocator: Allocator, attester_slashing: *const AttesterSlashing) !std.ArrayList(ValidatorIndex) {
    var att_set_1 = std.AutoArrayHashMap(ValidatorIndex, bool).init(allocator);
    defer att_set_1.deinit();

    for (attester_slashing.attestation_1.attesting_indices.items) |validator_index| {
        try att_set_1.put(validator_index, true);
    }

    var result = std.ArrayList(ValidatorIndex).init(allocator);
    for (attester_slashing.attestation_2.attesting_indices.items) |validator_index| {
        if (att_set_1.get(validator_index)) |_| {
            try result.append(validator_index);
        }
    }

    return result;
}
