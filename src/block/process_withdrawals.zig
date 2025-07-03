const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const params = @import("../params.zig");
const ForkSeq = @import("../config.zig").ForkSeq;
const Withdrawal = @import("../type.zig").Withdrawal;
const ValidatorIndex = @import("../type.zig").ValidatorIndex;
const ExecutionAddress = @import("../type.zig").ExecutionAddress;
const ExecutionPayload = @import("../type.zig").ExecutionPayload;
const hasExecutionWithdrawalCredential = @import("../utils/electra.zig").hasExecutionWithdrawalCredential;
const hasEth1WithdrawalCredential = @import("../utils/capella.zig").hasEth1WithdrawalCredential;
const getMaxEffectiveBalance = @import("../utils//validator.zig").getMaxEffectiveBalance;
const decreaseBalance = @import("../utils//balance.zig").decreaseBalance;

const WithdrawalsResult = struct {
    withwrawals: std.ArrayList(Withdrawal),
    sampled_validators: usize,
    processed_partial_withdrawals_count: usize,

    pub fn init(allocator: Allocator) !WithdrawalsResult {
        return WithdrawalsResult{
            .withwrawals = try std.ArrayList(Withdrawal).init(allocator),
            .sampled_validators = 0,
            .processed_partial_withdrawals_count = 0,
        };
    }

    pub fn deinit(self: *WithdrawalsResult, allocator: Allocator) void {
        self.withwrawals.deinit(allocator);
    }
};

// TODO: support capella.FullOrBlindedExecutionPayload
pub fn processWithdrawals(allocator: Allocator, fork: ForkSeq, cached_state: *CachedBeaconStateAllForks, payload: *const ExecutionPayload) !void {
    const state = cached_state.state;
    // processedPartialWithdrawalsCount is withdrawals coming from EL since electra (EIP-7002)
    const expected_withdrawals_result = try getExpectedWithdrawals(allocator, fork, cached_state);
    const processed_partial_withdrawals_count = expected_withdrawals_result.processed_partial_withdrawals_count;
    const expected_withdrawals = expected_withdrawals_result.withwrawals.items;
    const num_withdrawals = expected_withdrawals.len;

    // TODO: if (isCapellaPayloadHeader(payload)) {
    if (expected_withdrawals.len != payload.withdrawals.items.len) {
        return error.InvalidWithdrawalsLength;
    }
    for (0..num_withdrawals) |i| {
        const withdrawal = expected_withdrawals[i];
        // TODO: equals api https://github.com/ChainSafe/ssz-z/issues/27
        if (!ssz.capella.Withdrawal.equals(withdrawal, payload.withdrawals.items[i])) {
            return error.WithdrawalMismatch;
        }
    }

    for (0..num_withdrawals) |i| {
        const withdrawal = expected_withdrawals[i];
        decreaseBalance(state, withdrawal.validator_index, withdrawal.amount);
    }

    if (fork >= ForkSeq.electra) {
        state.setPendingPartialWithdrawals(try state.sliceFromPendingPartialWithdrawals(processed_partial_withdrawals_count));
    }

    // Update the nextWithdrawalIndex
    if (expected_withdrawals.len > 0) {
        const latest_withdrawal = expected_withdrawals[expected_withdrawals.len - 1];
        state.setNextWithdrawalIndex(latest_withdrawal.index + 1);
    }

    // Update the nextWithdrawalValidatorIndex
    if (expected_withdrawals.len == preset.MAX_WITHDRAWALS_PER_PAYLOAD) {
        // All slots filled, nextWithdrawalValidatorIndex should be validatorIndex having next turn
        state.setNextWithdrawalValidatorIndex((expected_withdrawals[expected_withdrawals.len - 1].validator_index + 1) % state.getValidatorsCount());
    } else {
        // expected withdrawals came up short in the bound, so we move nextWithdrawalValidatorIndex to
        // the next post the bound
        state.setNextWithdrawalValidatorIndex((state.getNextWithdrawalValidatorIndex() + preset.MAX_VALIDATORS_PER_WITHDRAWALS_SWEEP) % state.getValidatorsCount());
    }
}

// Consumer should deinit WithdrawalsResult with .deinit() after use
pub fn getExpectedWithdrawals(allocator: Allocator, fork: ForkSeq, cached_state: *CachedBeaconStateAllForks) !WithdrawalsResult {
    if (fork < ForkSeq.capella) {
        return error.InvalidForkSequence;
    }

    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;

    const epoch = epoch_cache.epoch;
    var withdrawal_index = state.getNextWithdrawalIndex();
    const validators = state.getValidators();
    const balances = state.getBalances();
    const next_withdrawal_validator_index = state.getNextWithdrawalValidatorIndex();

    var withdrawals_result = try WithdrawalsResult.init(allocator);
    var withdrawal_balances = std.AutoHashMap(ValidatorIndex, usize).init(allocator);
    const is_post_electra = fork >= ForkSeq.electra;
    // partial_withdrawals_count is withdrawals coming from EL since electra (EIP-7002)
    var processed_partial_withdrawals_count: u64 = 0;

    if (is_post_electra) {
        // TODO: this optimization logic is not needed for TreeView
        // MAX_PENDING_PARTIALS_PER_WITHDRAWALS_SWEEP = 8, PENDING_PARTIAL_WITHDRAWALS_LIMIT: 134217728 so we should only call getAllReadonly() if it makes sense
        // pendingPartialWithdrawals comes from EIP-7002 smart contract where it takes fee so it's more likely than not validator is in correct condition to withdraw
        // also we may break early if withdrawableEpoch > epoch
        for (0..state.getPendingPartialWithdrawalCount()) |i| {
            const withdrawal = state.getPendingPartialWithdrawal(i);
            // TODO: define MAX_PENDING_PARTIALS_PER_WITHDRAWALS_SWEEP
            if (withdrawal.withdrawable_epoch > epoch or withdrawals_result.withwrawals.items.len == preset.MAX_PENDING_PARTIALS_PER_WITHDRAWALS_SWEEP) {
                break;
            }

            const validator = validators.items[withdrawal.validator_index];
            const total_withdrawn = try withdrawal_balances.getOrPut(validator.index, 0);
            const balance = balances.items[withdrawal.validator_index] - total_withdrawn;

            if (validator.exit_epoch == params.FAR_FUTURE_EPOCH and
                validator.effective_balance >= preset.MIN_ACTIVATION_BALANCE and
                balance > preset.MIN_ACTIVATION_BALANCE)
            {
                const balance_over_min_activation_balance = balance - preset.MIN_ACTIVATION_BALANCE;
                const withdrawable_balance = if (balance_over_min_activation_balance < withdrawal.amount) balance_over_min_activation_balance else withdrawal.amount;
                var execution_address: ExecutionAddress = undefined;
                std.mem.copyForwards(u8, &execution_address, validator.withdrawal_credentials[12..]);
                try withdrawals_result.withwrawals.append(.{
                    .index = withdrawal_index,
                    .validator_index = withdrawal.validator_index,
                    .address = execution_address,
                    .amount = withdrawable_balance,
                });
                withdrawal_index += 1;
                try withdrawal_balances.put(withdrawal.validator_index, total_withdrawn + withdrawable_balance);
            }
            processed_partial_withdrawals_count += 1;
        }
    }

    const bound = @min(validators.items.len, preset.MAX_VALIDATORS_PER_WITHDRAWALS_SWEEP);
    // Just run a bounded loop max iterating over all withdrawals
    // however breaks out once we have MAX_WITHDRAWALS_PER_PAYLOAD
    var n: usize = 0;
    while (n < bound) : (n += 1) {
        // Get next validator in turn
        const validator_index = (next_withdrawal_validator_index + n) % validators.items.len;
        const validator = validators.items[validator_index];
        const withdraw_balance = try withdrawal_balances.getOrPut(validator_index, 0);
        const balance = if (is_post_electra) {
            // Deduct partially withdrawn balance already queued above
            balances.items[validator_index] - withdraw_balance;
        } else {
            balances.items[validator_index];
        };
        const withdrawable_epoch = validator.withdrawable_epoch;
        const withdrawal_credentials = validator.withdrawal_credentials;
        const effective_balance = validator.effective_balance;
        const has_withdrawable_credentials = if (is_post_electra) hasExecutionWithdrawalCredential(withdrawal_credentials) else hasEth1WithdrawalCredential(withdrawal_credentials);
        // early skip for balance = 0 as its now more likely that validator has exited/slashed with
        // balance zero than not have withdrawal credentials set
        if (balance == 0 or !has_withdrawable_credentials) {
            continue;
        }

        // capella full withdrawal
        if (withdrawable_epoch <= epoch) {
            var execution_address: ExecutionAddress = undefined;
            std.mem.copyForwards(u8, &execution_address, validator.withdrawal_credentials[12..]);
            try withdrawals_result.withwrawals.append(.{
                .index = withdrawal_index,
                .validator_index = validator_index,
                .address = execution_address,
                .amount = balance,
            });
        } else if (effective_balance == if (is_post_electra) getMaxEffectiveBalance(withdrawal_credentials) else preset.MAX_EFFECTIVE_BALANCE and balance > effective_balance) {
            // capella partial withdrawal
            const partial_amount = balance - effective_balance;
            var execution_address: ExecutionAddress = undefined;
            std.mem.copyForwards(u8, &execution_address, validator.withdrawal_credentials[12..]);
            try withdrawals_result.withwrawals.append(.{
                .index = withdrawal_index,
                .validator_index = validator_index,
                .address = execution_address,
                .amount = partial_amount,
            });
            withdrawal_index += 1;
            try withdrawal_balances.put(validator_index, withdraw_balance + partial_amount);
        }

        // Break if we have enough to pack the block
        if (withdrawals_result.withwrawals.items.len >= preset.MAX_WITHDRAWALS_PER_PAYLOAD) {
            break;
        }
    }

    withdrawals_result.sampled_validators = n;
    withdrawals_result.processed_partial_withdrawals_count = processed_partial_withdrawals_count;
    return withdrawals_result;
}
