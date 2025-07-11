const std = @import("std");
const Allocator = std.mem.Allocator;
const ForkSeq = @import("../types/fork.zig").ForkSeq;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const preset = @import("consensus_types").preset;
const params = @import("../params.zig");
const getAttestationDeltas = @import("./get_attestation_deltas.zig").getAttestationDeltas;
const getRewardsAndPenaltiesAltair = @import("./get_rewards_and_penalties.zig").getRewardsAndPenaltiesAltair;
const RewardsPenaltiesArray = @import("./get_rewards_and_penalties.zig").RewardsPenaltiesArray;

pub fn processRewardsAndPenalties(allocator: Allocator, cached_state: CachedBeaconStateAllForks, cache: EpochTransitionCache) void {
    // No rewards are applied at the end of `GENESIS_EPOCH` because rewards are for work done in the previous epoch
    if (cache.current_epoch == params.GENESIS_EPOCH) {
        return;
    }

    const state = cached_state.state;

    const rewards_and_penalties = getRewardsAndPenalties(allocator, cached_state, cache);
    const rewards = rewards_and_penalties.rewards;
    const penalties = rewards_and_penalties.penalties;
    defer rewards.deinit();
    defer penalties.deinit();

    for (rewards.items, 0..) |reward, i| {
        const result = state.getBalance(i) + reward - penalties[i];
        state.setBalance(i, @max(result, 0));
    }

    // TODO this is naive version, consider caching balances here when switching to TreeView
}

pub fn getRewardsAndPenalties(allocator: Allocator, cached_state: CachedBeaconStateAllForks, cache: EpochTransitionCache) RewardsPenaltiesArray {
    const state = cached_state.state;
    const fork = cached_state.config.getForkSeq(state.getSlot());
    return if (fork == ForkSeq.phase0) getAttestationDeltas(allocator, cached_state, cache) else getRewardsAndPenaltiesAltair(allocator, cached_state, cache);
}
