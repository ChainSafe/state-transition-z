const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const params = @import("../params.zig");
const Slot = ssz.primitive.Slot.Type;
const Epoch = ssz.primitive.Epoch.Type;
const SyncPeriod = ssz.primitive.SyncPeriod.Type;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const Gwei = ssz.primitive.Gwei.Type;
const getActivationExitChurnLimit = @import("../utils/validator.zig").getActivationExitChurnLimit;

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

pub fn computeExitEpochAndUpdateChurn(cached_state: *CachedBeaconStateAllForks, exit_balance: Gwei) u64 {
    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;
    var earliest_exit_epoch = @max(state.getEarliestExitEpoch(), computeActivationExitEpoch(epoch_cache.epoch));
    const per_epoch_churn = getActivationExitChurnLimit(epoch_cache);

    // New epoch for exits.
    var exit_balance_to_consume = if (state.getEarliestExitEpoch() < earliest_exit_epoch) per_epoch_churn else state.getExitBalanceToConsume();

    // Exit doesn't fit in the current earliest epoch.
    if (exit_balance > exit_balance_to_consume) {
        const balance_to_process = exit_balance - exit_balance_to_consume;
        const additional_epochs = @divFloor(balance_to_process - 1, per_epoch_churn) + 1;
        earliest_exit_epoch += additional_epochs;
        exit_balance_to_consume += additional_epochs * per_epoch_churn;
    }

    // Consume the balance and update state variables.
    state.setExitBalanceToConsume(exit_balance_to_consume - exit_balance);
    state.setEarliestExitEpoch(earliest_exit_epoch);

    return state.getEarliestExitEpoch();
}

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
