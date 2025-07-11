const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("../types/fork.zig").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ssz = @import("consensus_types");
const preset = ssz.preset;

pub fn processParticipationRecordUpdates(cached_state: *CachedBeaconStateAllForks) void {
    const state = cached_state.state;
    // rotate current/previous epoch attestations
    state.setPreviousEpochPendingAttestations(state.getCurrentEpochPendingAttestations());

    // Reset list to empty
    state.setCurrentEpochPendingAttestations(ssz.phase0.EpochAttestations.default_value);
}
