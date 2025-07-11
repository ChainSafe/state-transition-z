const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("../types/fork.zig").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ssz = @import("consensus_types");
const preset = ssz.preset;

pub fn processRandaoMixesReset(cached_state: *CachedBeaconStateAllForks, cache: *const EpochTransitionCache) void {
    const state = cached_state.state;
    const current_epoch = cache.current_epoch;
    const next_epoch = current_epoch + 1;

    // reset randao mix
    state.setRandaoMix(next_epoch % preset.EPOCHS_PER_HISTORICAL_VECTOR, state.getRanDaoMix(current_epoch % preset.EPOCHS_PER_HISTORICAL_VECTOR));
}
