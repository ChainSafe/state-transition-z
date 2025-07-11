const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("params").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ssz = @import("consensus_types");
const preset = ssz.preset;

pub fn processHistoricalSummariesUpdate(cached_state: *CachedBeaconStateAllForks, cache: *const EpochTransitionCache) void {
    const state = cached_state.state;
    const next_epoch = cache.current_epoch + 1;

    // set historical root accumulator
    if (next_epoch % @divFloor(preset.SLOTS_PER_HISTORICAL_ROOT, preset.SLOTS_PER_EPOCH) == 0) {
        state.addHistoricalSummary(.{
            // TODO(ssz) define ssz.BlockRoots
            .block_summary_root = ssz.phase0.BlockRoots.hashTreeRoot(),
            .state_summary_root = ssz.phase0.BlockRoots.hashTreeRoot(),
        });
    }
}
