const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const preset = @import("consensus_types").preset;
const MIN_EPOCHS_TO_INACTIVITY_PENALTY = preset.MIN_EPOCHS_TO_INACTIVITY_PENALTY;

pub fn getFinalityDelay(cached_state: *const CachedBeaconStateAllForks) u64 {
    // previous_epoch = epoch - 1
    return cached_state.getEpochCache().epoch - 1 - cached_state.state.finalizedCheckpoint().epoch;
}

/// If the chain has not been finalized for >4 epochs, the chain enters an "inactivity leak" mode,
/// where inactive validators get progressively penalized more and more, to reduce their influence
/// until blocks get finalized again. See here (https://github.com/ethereum/annotated-spec/blob/master/phase0/beacon-chain.md#inactivity-quotient) for what the inactivity leak is, what it's for and how
/// it works.
pub fn isInInactivityLeak(state: *const CachedBeaconStateAllForks) bool {
    return getFinalityDelay(state) > MIN_EPOCHS_TO_INACTIVITY_PENALTY;
}
