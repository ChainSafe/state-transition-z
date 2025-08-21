const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("params").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ssz = @import("consensus_types");
const preset = ssz.preset;

pub fn processParticipationRecordUpdates(allocator: Allocator, cached_state: *CachedBeaconStateAllForks) void {
    const state = cached_state.state;
    // rotate current/previous epoch attestations
    state.rotateEpochPendingAttestations(allocator);
}
