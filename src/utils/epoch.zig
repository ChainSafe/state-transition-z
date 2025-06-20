const ssz = @import("consensus_types");
const preset = ssz.preset;
const params = @import("../params.zig");
const Slot = ssz.primitive.Slot.Type;
const Epoch = ssz.primitive.Epoch.Type;
const SyncPeriod = ssz.primitive.SyncPeriod.Type;
const BeaconStateAllForks = @import("../beacon_state.zig").BeaconStateAllForks;
const Gwei = ssz.primitive.Gwei.Type;

pub fn computeEpochAtSlot(slot: Slot) Epoch {
    return @divFloor(slot, preset.SLOTS_PER_EPOCH);
}

pub fn computeCheckpointEpochAtStateSlot(slot: Slot) Epoch {
    const epoch = computeEpochAtSlot(slot);
    return if (slot % preset.SLOTS_PER_EPOCH == 0)
        epoch
    else
        epoch + 1;
}

pub fn computeStartSlotAtEpoch(epoch: Epoch) Slot {
    return epoch * preset.SLOTS_PER_EPOCH;
}

pub fn computeEndSlotAtEpoch(epoch: Epoch) Slot {
    return computeStartSlotAtEpoch(epoch + 1) - 1;
}

pub fn computeActivationExitEpoch(epoch: Epoch) Epoch {
    return epoch + 1 + preset.MAX_SEED_LOOKAHEAD;
}

// TODO: model: CachedBeaconStateElectra
// pub fn computeExitEpochAndUpdateChurn(state: *BeaconStateAllForks, exit_balance: Gwei) u64 {
//   let earliest_exit_epoch = @max(state.getEarliestExitEpoch(), computeActivationExitEpoch(state.epoc))
// }

// TODO: computeConsolidationEpochAndUpdateChurn

pub fn getCurrentEpoch(state: BeaconStateAllForks) Epoch {
    return computeEpochAtSlot(state.getSlot());
}

pub fn getPreviousEpoch(state: BeaconStateAllForks) Epoch {
    const current_epoch = getCurrentEpoch(state);
    return if (current_epoch == params.GENESIS_EPOCH) params.GENESIS_EPOCH else current_epoch - 1;
}

pub fn computeSyncPeriodAtSlot(slot: Slot) SyncPeriod {
    return computeSyncPeriodAtEpoch(computeEpochAtSlot(slot));
}

pub fn computeSyncPeriodAtEpoch(epoch: Epoch) SyncPeriod {
    return @divFloor(epoch, preset.EPOCHS_PER_SYNC_COMMITTEE_PERIOD);
}

pub fn isStartSlotOfEpoch(slot: Slot) bool {
    return slot % preset.SLOTS_PER_EPOCH == 0;
}
