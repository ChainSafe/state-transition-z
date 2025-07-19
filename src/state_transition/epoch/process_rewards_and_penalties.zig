const std = @import("std");
const Allocator = std.mem.Allocator;
const ForkSeq = @import("params").ForkSeq;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const preset = @import("consensus_types").preset;
const params = @import("params");
const getAttestationDeltas = @import("./get_attestation_deltas.zig").getAttestationDeltas;
const getRewardsAndPenaltiesAltair = @import("./get_rewards_and_penalties.zig").getRewardsAndPenaltiesAltair;

pub fn processRewardsAndPenalties(allocator: Allocator, cached_state: *CachedBeaconStateAllForks, cache: *const EpochTransitionCache) !void {
    // No rewards are applied at the end of `GENESIS_EPOCH` because rewards are for work done in the previous epoch
    if (cache.current_epoch == params.GENESIS_EPOCH) {
        return;
    }

    const state = cached_state.state;

    const rewards = cache.rewards;
    const penalties = cache.penalties;
    try getRewardsAndPenalties(allocator, cached_state, cache, rewards, penalties);

    for (rewards, 0..) |reward, i| {
        const result = state.getBalance(i) + reward - penalties[i];
        state.setBalance(i, @max(result, 0));
    }

    // TODO this is naive version, consider caching balances here when switching to TreeView
}

pub fn getRewardsAndPenalties(allocator: Allocator, cached_state: CachedBeaconStateAllForks, cache: EpochTransitionCache, rewards: []u64, penalties: []u64) !void {
    const state = cached_state.state;
    const fork = cached_state.config.getForkSeq(state.getSlot());
    return if (fork == ForkSeq.phase0) try getAttestationDeltas(allocator, cached_state, cache, rewards, penalties) else try getRewardsAndPenaltiesAltair(allocator, cached_state, cache, rewards, penalties);
}
