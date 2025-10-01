const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("params").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const c = @import("constants");

/// Same to https://github.com/ethereum/eth2.0-specs/blob/v1.1.0-alpha.5/specs/altair/beacon-chain.md#has_flag
const TIMELY_TARGET = 1 << c.TIMELY_TARGET_FLAG_INDEX;

const HYSTERESIS_INCREMENT = preset.EFFECTIVE_BALANCE_INCREMENT / preset.HYSTERESIS_QUOTIENT;
const DOWNWARD_THRESHOLD = HYSTERESIS_INCREMENT * preset.HYSTERESIS_DOWNWARD_MULTIPLIER;
const UPWARD_THRESHOLD = HYSTERESIS_INCREMENT * preset.HYSTERESIS_UPWARD_MULTIPLIER;

/// this function also update EpochTransitionCache
pub fn processEffectiveBalanceUpdates(cached_state: *CachedBeaconStateAllForks, cache: *EpochTransitionCache) !usize {
    const state = cached_state.state;
    const epoch_cache = cached_state.getEpochCache();
    const validators = state.validators();
    const effective_balance_increments = epoch_cache.getEffectiveBalanceIncrements().items;
    var next_epoch_total_active_balance_by_increment: u64 = 0;

    // update effective balances with hysteresis

    // epochTransitionCache.balances is initialized in processRewardsAndPenalties()
    // and updated in processPendingDeposits() and processPendingConsolidations()
    // so it's recycled here for performance.
    const balances = if (cache.balances) |balances_arr| balances_arr.items else state.balances().items;
    const is_compounding_validator_arr = cache.is_compounding_validator_arr.items;

    var num_update: usize = 0;
    for (balances, 0..) |balance, i| {
        // PERF: It's faster to access to get() every single element (4ms) than to convert to regular array then loop (9ms)
        var effective_balance_increment = effective_balance_increments[i];
        var effective_balance = @as(u64, effective_balance_increment) * preset.EFFECTIVE_BALANCE_INCREMENT;
        const effective_balance_limit: u64 = if (state.isPreElectra()) preset.MAX_EFFECTIVE_BALANCE else blk: {
            // from electra, effectiveBalanceLimit is per validator
            if (is_compounding_validator_arr[i]) {
                break :blk preset.MAX_EFFECTIVE_BALANCE_ELECTRA;
            } else {
                break :blk preset.MIN_ACTIVATION_BALANCE;
            }
        };

        if (
        // too big
        effective_balance > balance + DOWNWARD_THRESHOLD or
            // too small. Check effective_balance < MAX_EFFECTIVE_BALANCE to prevent unnecessary updates
            (effective_balance < effective_balance_limit and effective_balance + UPWARD_THRESHOLD < balance))
        {
            // Update the state tree
            // Should happen rarely, so it's fine to update the tree
            var validator = validators.items[i];
            effective_balance = @min(
                balance - (balance % preset.EFFECTIVE_BALANCE_INCREMENT),
                effective_balance_limit,
            );
            validator.effective_balance = effective_balance;
            // Also update the fast cached version
            const new_effective_balance_increment: u16 = @intCast(@divFloor(effective_balance, preset.EFFECTIVE_BALANCE_INCREMENT));

            // TODO: describe issue. Compute progressive target balances
            // Must update target balances for consistency, see comments below
            if (state.isPostAltair()) {
                const delta_effective_balance_increment = new_effective_balance_increment - effective_balance_increment;
                const previous_epoch_participation = state.previousEpochParticipations().items;
                const current_epoch_participation = state.currentEpochParticipations().items;

                if (!validator.slashed) {
                    if (previous_epoch_participation[i] & TIMELY_TARGET == TIMELY_TARGET) {
                        epoch_cache.previous_target_unslashed_balance_increments += delta_effective_balance_increment;
                    }

                    // currentTargetUnslashedBalanceIncrements is transfered to previousTargetUnslashedBalanceIncrements in afterEpochTransitionCache
                    // at epoch transition of next epoch (in EpochTransitionCache), prevTargetUnslStake is calculated based on newEffectiveBalanceIncrement
                    if (current_epoch_participation[i] & TIMELY_TARGET == TIMELY_TARGET) {
                        epoch_cache.current_target_unslashed_balance_increments += delta_effective_balance_increment;
                    }
                }
            }

            effective_balance_increment = new_effective_balance_increment;
            effective_balance_increments[i] = effective_balance_increment;
            num_update += 1;
        }

        // TODO: Do this in afterEpochTransitionCache, looping a Uint8Array should be very cheap
        if (cache.is_active_next_epoch[i]) {
            // We track nextEpochTotalActiveBalanceByIncrement as ETH to fit total network balance in a JS number (53 bits)
            next_epoch_total_active_balance_by_increment += effective_balance_increment;
        }
    }

    cache.next_epoch_total_active_balance_by_increment = next_epoch_total_active_balance_by_increment;
    return num_update;
}
