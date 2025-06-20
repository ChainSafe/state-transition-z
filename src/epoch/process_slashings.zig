const ssz = @import("consensus_types");
const preset = ssz.preset;
const BeaconStateAllForks = @import("../beacon_state.zig").BeaconStateAllForks;

pub fn getTotalSlashingsByIncrement(state: *const BeaconStateAllForks) u64 {
    var total_slashings_by_increment: u64 = 0;
    const count = state.getSlashingCount();

    for (0..count) |i| {
        const slashing = state.getSlashing(i);
        total_slashings_by_increment += @divFloor(slashing, preset.EFFECTIVE_BALANCE_INCREMENT);
    }

    return total_slashings_by_increment;
}
