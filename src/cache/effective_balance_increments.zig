const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const getReferenceCount = @import("../utils/reference_count.zig").getReferenceCount;
const EFFECTIVE_BALANCE_INCREMENT = preset.EFFECTIVE_BALANCE_INCREMENT;

pub const EffectiveBalanceIncrements = std.ArrayList(u16);
pub const EffectiveBalanceIncrementsRc = getReferenceCount(EffectiveBalanceIncrements);

// TODO: implement reference counting strategy

pub fn getEffectiveBalanceIncrementsZeroed(allocator: Allocator, len: usize) !EffectiveBalanceIncrements {
    var increments = EffectiveBalanceIncrements.init(allocator);
    try increments.ensureTotalCapacity(len);
    for (0..len) |_| {
        try increments.append(0);
    }
    return increments;
}

pub fn getEffectiveBalanceIncrementsWithLen(allocator: Allocator, validator_count: usize) !EffectiveBalanceIncrements {
    const len = 1024 * @divFloor(validator_count, 1024);
    return getEffectiveBalanceIncrementsZeroed(allocator, len);
}

pub fn getEffectiveBalanceIncrements(allocator: Allocator, state: BeaconStateAllForks) !EffectiveBalanceIncrements {
    var increments = EffectiveBalanceIncrements.init(allocator);
    const validator_count = state.getValidatorsCount();
    increments.ensureTotalCapacity(validator_count);

    for (0..validator_count) |i| {
        const validator = state.getValidator(i);
        try increments.append(@divFloor(validator.effective_balance, preset.EFFECTIVE_BALANCE_INCREMENT));
    }
}

// TODO: unit tests
