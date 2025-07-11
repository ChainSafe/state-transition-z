const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("../types/fork.zig").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const decreaseBalance = @import("../utils/balance.zig").decreaseBalance;
const increaseBalance = @import("../utils/balance.zig").increaseBalance;

pub fn processPendingConsolidations(cached_state: *CachedBeaconStateAllForks, cache: *EpochTransitionCache) !void {
    const epoch_cache = cached_state.epoch_cache;
    const state = cached_state.state;
    const next_epoch = epoch_cache.epoch + 1;
    var next_pending_consolidation: usize = 0;
    const validators = state.getValidators();

    var chunk_start_index = 0;
    const chunk_size = 100;
    const pending_consolidations_length = state.pending_consolidations.len;
    outer: while (chunk_start_index < pending_consolidations_length) : (chunk_start_index += chunk_size) {
        // TODO(ssz): implement getReadonlyByRange api for TreeView
        const consolidation_chunk = state.getPendingConsolidations()[chunk_start_index..@min(chunk_start_index + chunk_size, pending_consolidations_length)];
        for (consolidation_chunk) |pending_consolidation| {
            const source_index = pending_consolidation.source_index;
            const target_index = pending_consolidation.target_index;
            const source_validator = validators.items[source_index];

            if (source_validator.slashed) {
                next_pending_consolidation += 1;
                continue;
            }

            if (source_validator.withdrawable_epoch > next_epoch) {
                break :outer;
            }

            // Calculate the consolidated balance
            const source_effective_balance = @min(state.getBalance(source_index), source_validator.effective_balance);

            // Move active balance to target. Excess balance is withdrawable.
            decreaseBalance(state, source_index, source_effective_balance);
            increaseBalance(state, target_index, source_effective_balance);
            if (cache.balances) |cached_balances| {
                cached_balances.items[source_index] -= source_effective_balance;
                cached_balances.items[target_index] += source_effective_balance;
            }

            next_pending_consolidation += 1;
        }
    }
    cached_state.setPendingConsolidations(state.sliceFromPendingConsolidations(next_pending_consolidation));
}
