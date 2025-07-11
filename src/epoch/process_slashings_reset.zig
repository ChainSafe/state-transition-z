const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("params").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ssz = @import("consensus_types");
const preset = ssz.preset;

/// Resets slashings for the next epoch.
/// PERF: Almost no (constant) cost
pub fn processSlashingsReset(cached_state: *CachedBeaconStateAllForks, cache: *const EpochTransitionCache) void {
    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;
    const next_epoch = cache.epoch + 1;

    // reset slashings
    const slash_index = next_epoch % preset.EPOCHS_PER_SLASHINGS_VECTOR;
    const old_slashing_value_by_increment = state.getSlashing(slash_index) / preset.EFFECTIVE_BALANCE_INCREMENT;
    state.setSlashing(slash_index, 0);
    epoch_cache.total_slashings_by_increment = @max(0, epoch_cache.total_slashings_by_increment - old_slashing_value_by_increment);
}
