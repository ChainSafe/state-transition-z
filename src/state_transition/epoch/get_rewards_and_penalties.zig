const std = @import("std");
const Allocator = std.mem.Allocator;
const attester_status = @import("../utils/attester_status.zig");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const preset = @import("consensus_types").preset;
const params = @import("params");
const constants = @import("../constants.zig");

const EFFECTIVE_BALANCE_INCREMENT = preset.EFFECTIVE_BALANCE_INCREMENT;
const ForkSeq = @import("params").ForkSeq;
const INACTIVITY_PENALTY_QUOTIENT_ALTAIR = preset.INACTIVITY_PENALTY_QUOTIENT_ALTAIR;
const INACTIVITY_PENALTY_QUOTIENT_BELLATRIX = preset.INACTIVITY_PENALTY_QUOTIENT_BELLATRIX;
const PARTICIPATION_FLAG_WEIGHTS = params.PARTICIPATION_FLAG_WEIGHTS;
const TIMELY_HEAD_FLAG_INDEX = params.TIMELY_HEAD_FLAG_INDEX;
const TIMELY_SOURCE_FLAG_INDEX = params.TIMELY_SOURCE_FLAG_INDEX;
const TIMELY_TARGET_FLAG_INDEX = params.TIMELY_TARGET_FLAG_INDEX;
const WEIGHT_DENOMINATOR = params.WEIGHT_DENOMINATOR;

const FLAG_ELIGIBLE_ATTESTER = attester_status.FLAG_ELIGIBLE_ATTESTER;
const FLAG_PREV_HEAD_ATTESTER_UNSLASHED = attester_status.FLAG_PREV_HEAD_ATTESTER_UNSLASHED;
const FLAG_PREV_SOURCE_ATTESTER_UNSLASHED = attester_status.FLAG_PREV_SOURCE_ATTESTER_UNSLASHED;
const FLAG_PREV_TARGET_ATTESTER_UNSLASHED = attester_status.FLAG_PREV_TARGET_ATTESTER_UNSLASHED;
const hasMarkers = attester_status.hasMarkers;

const isInInactivityLeak = @import("../utils/finality.zig").isInInactivityLeak;

const RewardPenaltyItem = struct {
    base_reward: u64,
    timely_source_reward: u64,
    timely_source_penalty: u64,
    timely_target_reward: u64,
    timely_target_penalty: u64,
    timely_head_reward: u64,
};

/// consumer should deinit `rewards` and `penalties` arrays
pub fn getRewardsAndPenaltiesAltair(allocator: Allocator, cached_state: *const CachedBeaconStateAllForks, cache: *const EpochTransitionCache, rewards: []u64, penalties: []u64) !void {
    const state = cached_state.state;
    const validator_count = state.getValidatorsCount();
    const active_increments = cache.total_active_stake_by_increment;
    if (rewards.len != validator_count or penalties.len != validator_count) {
        return error.InvalidArrayLength;
    }
    @memset(rewards, 0);
    @memset(penalties, 0);

    const is_in_inactivity_leak = isInInactivityLeak(cached_state);
    // effectiveBalance is multiple of EFFECTIVE_BALANCE_INCREMENT and less than MAX_EFFECTIVE_BALANCE
    // so there are limited values of them like 32, 31, 30
    const reward_penalty_item_cache = std.AutoHashMap(u64, RewardPenaltyItem).init(allocator);
    defer reward_penalty_item_cache.deinit();

    const config = cached_state.config;
    const epoch_cache = cached_state.getEpochCache();
    const fork = config.getForkSeq(state.getSlot());

    const inactivity_penality_multiplier =
        if (fork == ForkSeq.altair) INACTIVITY_PENALTY_QUOTIENT_ALTAIR else INACTIVITY_PENALTY_QUOTIENT_BELLATRIX;
    const penalty_denominator = config.INACTIVITY_SCORE_BIAS * inactivity_penality_multiplier;

    const flags = cache.flags;
    for (flags, 0..) |flag, i| {
        if (!hasMarkers(flag, FLAG_ELIGIBLE_ATTESTER)) {
            continue;
        }

        const effective_balance_increment = epoch_cache.effective_balance_increment[i];

        var reward_penalty_item = reward_penalty_item_cache.get(effective_balance_increment);
        if (reward_penalty_item == null) {
            const base_reward = effective_balance_increment * cache.base_reward_per_increment;
            const ts_weigh = PARTICIPATION_FLAG_WEIGHTS[TIMELY_SOURCE_FLAG_INDEX];
            const tt_weigh = PARTICIPATION_FLAG_WEIGHTS[TIMELY_TARGET_FLAG_INDEX];
            const th_weigh = PARTICIPATION_FLAG_WEIGHTS[TIMELY_HEAD_FLAG_INDEX];
            const ts_unslashed_participating_increments = cache.prev_epoch_unslashed_stake.source_stake_by_increment;
            const tt_unslashed_participating_increments = cache.prev_epoch_unslashed_stake.target_stake_by_increment;
            const th_unslashed_participating_increments = cache.prev_epoch_unslashed_stake.head_stake_by_increment;
            const ts_reward_numerator = base_reward * ts_weigh * ts_unslashed_participating_increments;
            const tt_reward_numerator = base_reward * tt_weigh * tt_unslashed_participating_increments;
            const th_reward_numerator = base_reward * th_weigh * th_unslashed_participating_increments;
            reward_penalty_item = .{
                .base_reward = base_reward,
                .timely_source_reward = @divFloor(ts_reward_numerator, active_increments * WEIGHT_DENOMINATOR),
                .timely_target_reward = @divFloor(tt_reward_numerator, active_increments * WEIGHT_DENOMINATOR),
                .timely_head_reward = @divFloor(th_reward_numerator, active_increments * WEIGHT_DENOMINATOR),
                .timely_source_penalty = @divFloor(base_reward * ts_weigh, WEIGHT_DENOMINATOR),
                .timely_target_penalty = @divFloor(base_reward * tt_weigh, WEIGHT_DENOMINATOR),
            };
        }

        const timely_source_reward = reward_penalty_item.?.timely_source_reward;
        const timely_source_penalty = reward_penalty_item.?.timely_source_penalty;
        const timely_target_reward = reward_penalty_item.?.timely_target_reward;
        const timely_target_penalty = reward_penalty_item.?.timely_target_penalty;
        const timely_head_reward = reward_penalty_item.?.timely_head_reward;

        // same logic to getFlagIndexDeltas
        if (hasMarkers(flag, FLAG_PREV_SOURCE_ATTESTER_UNSLASHED)) {
            if (!is_in_inactivity_leak) {
                rewards[i] += timely_source_reward;
            }
        } else {
            penalties[i] += timely_source_penalty;
        }

        if (hasMarkers(flag, FLAG_PREV_TARGET_ATTESTER_UNSLASHED)) {
            if (!is_in_inactivity_leak) {
                rewards[i] += timely_target_reward;
            }
        } else {
            penalties[i] += timely_target_penalty;
        }

        if (hasMarkers(flag, FLAG_PREV_HEAD_ATTESTER_UNSLASHED) and !is_in_inactivity_leak) {
            rewards[i] += timely_head_reward;
        }

        // Same logic to getInactivityPenaltyDeltas
        // TODO: if we have limited value in inactivityScores we can provide a cache too
        if (!hasMarkers(flag, FLAG_PREV_TARGET_ATTESTER_UNSLASHED)) {
            const penalty_numerator = effective_balance_increment * EFFECTIVE_BALANCE_INCREMENT * state.getInactivityScore(i);
            penalties[i] += @divFloor(penalty_numerator, penalty_denominator);
        }
    }
}
