const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const types = @import("../types.zig");
const Epoch = types.Epoch;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ForkSeq = @import("params").ForkSeq;
const computeActivationExitEpoch = @import("../utils/epoch.zig").computeActivationExitEpoch;
const initiateValidatorExit = @import("../utils/validator.zig").initiateValidatorExit;

pub fn processRegistryUpdates(cached_state: *const CachedBeaconStateAllForks, cache: EpochTransitionCache) !void {
    const epoch_cache = cached_state.getEpochCache();
    const state = cached_state.state;

    // Get the validators sub tree once for all the loop
    const validators = state.getValidators();

    // TODO: Batch set this properties in the tree at once with setMany() or setNodes()

    // process ejections
    for (cache.indices_to_eject) |index| {
        // set validator exit epoch and withdrawable epoch
        // TODO: Figure out a way to quickly set properties on the validators tree
        const validator = validators.get(index);
        initiateValidatorExit(state, &validator);
        state.setValidator(index, validator);
    }

    // set new activation eligibilities
    for (cache.indices_eligible_for_activation_queue) |index| {
        validators.get(index).activation_eligibility_epoch = epoch_cache.epoch + 1;
    }

    const finality_epoch = state.getFinalizedCheckpoint().epoch;
    const len = if (state.isPreElectra()) @min(cache.indices_eligible_for_activation.items.len, epoch_cache.activation_churn_limit) else cache.indices_eligible_for_activation.items.len;
    const activation_epoch = computeActivationExitEpoch(cache.current_epoch);

    // dequeue validators for activation up to churn limit
    for (0..len) |i| {
        const validator_index = cache.indices_eligible_for_activation.items[i];
        const validator = validators[validator_index];
        // placement in queue is finalized
        if (validator.activation_eligibility_epoch > finality_epoch) {
            // remaining validators all have an activationEligibilityEpoch that is higher anyway, break early
            // activationEligibilityEpoch has been sorted in epoch process in ascending order.
            // At that point the finalityEpoch was not known because processJustificationAndFinalization() wasn't called yet.
            // So we need to filter by finalityEpoch here to comply with the spec.
            break;
        }
        validator.activation_epoch = activation_epoch;
    }
}
