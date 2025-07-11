const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("../types/fork.zig").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ssz = @import("consensus_types");
const preset = ssz.preset;

pub fn processHistoricalRootsUpdate(cached_state: *CachedBeaconStateAllForks, cache: *const EpochTransitionCache) void {
    const state = cached_state.state;
    const next_epoch = cache.current_epoch + 1;

    // set historical root accumulator
    if (next_epoch % @divFloor(preset.EPOCHS_PER_HISTORICAL_ROOT, preset.SLOTS_PER_EPOCH) == 0) {
        state.addHistoricalRoot(
            // HistoricalBatchRoots = Non-spec'ed helper type to allow efficient hashing in epoch transition.
            // This type is like a 'Header' of HistoricalBatch where its fields are hashed.
            ssz.phase0.HistoricalBatch.hashTreeRoot(.{
                // TODO(ssz) define missing types in ssz
                .block_roots = ssz.phase0.BlockRoots.hashTreeRoot(state.getBlockRoots()),
                .state_roots = ssz.phase0.StateRoots.hashTreeRoot(state.getStateRoots()),
            }));
    }
}
