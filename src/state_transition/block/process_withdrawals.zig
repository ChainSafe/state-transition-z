const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const Root = ssz.primitive.Root.Type;
const preset = @import("preset").preset;
const c = @import("constants");
const ForkSeq = @import("config").ForkSeq;
const Withdrawal = ssz.capella.Withdrawal.Type;
const Withdrawals = ssz.capella.Withdrawals.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const ExecutionAddress = ssz.primitive.ExecutionAddress.Type;
const PendingPartialWithdrawal = ssz.electra.PendingPartialWithdrawal.Type;
const ExecutionPayload = @import("../types/execution_payload.zig").ExecutionPayload;
const hasExecutionWithdrawalCredential = @import("../utils/electra.zig").hasExecutionWithdrawalCredential;
const hasEth1WithdrawalCredential = @import("../utils/capella.zig").hasEth1WithdrawalCredential;
const getMaxEffectiveBalance = @import("../utils/validator.zig").getMaxEffectiveBalance;
const decreaseBalance = @import("../utils/balance.zig").decreaseBalance;

pub const WithdrawalsResult = struct {
    withdrawals: Withdrawals,
    sampled_validators: usize = 0,
    processed_partial_withdrawals_count: usize = 0,
};

/// right now for the implementation we pass in processBlock()
/// for the spec, we pass in params from operations.zig
/// TODO: spec and implementation should be the same
/// refer to https://github.com/ethereum/consensus-specs/blob/dev/specs/electra/beacon-chain.md#modified-process_withdrawals
pub fn processWithdrawals(
    allocator: Allocator,
    cached_state: *const CachedBeaconStateAllForks,
    expected_withdrawals_result: WithdrawalsResult,
    payload_withdrawals_root: Root,
) !void {
    const state = cached_state.state;
    // processedPartialWithdrawalsCount is withdrawals coming from EL since electra (EIP-7002)
    const processed_partial_withdrawals_count = expected_withdrawals_result.processed_partial_withdrawals_count;
    const expected_withdrawals = expected_withdrawals_result.withdrawals.items;
    const num_withdrawals = expected_withdrawals.len;

    var expected_withdrawals_root: [32]u8 = undefined;
    try ssz.capella.Withdrawals.hashTreeRoot(allocator, &expected_withdrawals_result.withdrawals, &expected_withdrawals_root);

    if (!std.mem.eql(u8, &expected_withdrawals_root, &payload_withdrawals_root)) {
        return error.WithdrawalsRootMismatch;
    }

    for (0..num_withdrawals) |i| {
        const withdrawal = expected_withdrawals[i];
        decreaseBalance(state, withdrawal.validator_index, withdrawal.amount);
    }

    if (state.isPostElectra()) {
        const pending_partial_withdrawals = state.pendingPartialWithdrawals();
        const keep_len = pending_partial_withdrawals.items.len - processed_partial_withdrawals_count;

        std.mem.copyForwards(PendingPartialWithdrawal, pending_partial_withdrawals.items[0..keep_len], pending_partial_withdrawals.items[processed_partial_withdrawals_count..]);
        pending_partial_withdrawals.shrinkRetainingCapacity(keep_len);
    }

    const next_withdrawal_index = state.nextWithdrawalIndex();
    // Update the nextWithdrawalIndex
    if (expected_withdrawals.len > 0) {
        const latest_withdrawal = expected_withdrawals[expected_withdrawals.len - 1];
        next_withdrawal_index.* = latest_withdrawal.index + 1;
    }

    // Update the nextWithdrawalValidatorIndex
    const nextWithdrawalValidatorIndex = state.nextWithdrawalValidatorIndex();
    if (expected_withdrawals.len == preset.MAX_WITHDRAWALS_PER_PAYLOAD) {
        // All slots filled, nextWithdrawalValidatorIndex should be validatorIndex having next turn
        nextWithdrawalValidatorIndex.* =
            (expected_withdrawals[expected_withdrawals.len - 1].validator_index + 1) % state.validators().items.len;
    } else {
        // expected withdrawals came up short in the bound, so we move nextWithdrawalValidatorIndex to
        // the next post the bound
        nextWithdrawalValidatorIndex.* = (nextWithdrawalValidatorIndex.* + preset.MAX_VALIDATORS_PER_WITHDRAWALS_SWEEP) % state.validators().items.len;
    }
}

// Consumer should deinit WithdrawalsResult with .deinit() after use
pub fn getExpectedWithdrawals(
    allocator: Allocator,
    withdrawals_result: *WithdrawalsResult,
    withdrawal_balances: *std.AutoHashMap(ValidatorIndex, usize),
    cached_state: *const CachedBeaconStateAllForks,
) !void {
    const state = cached_state.state;
    if (state.isPreCapella()) {
        return error.InvalidForkSequence;
    }

    const epoch_cache = cached_state.getEpochCache();

    const epoch = epoch_cache.epoch;
    var withdrawal_index = state.nextWithdrawalIndex().*;
    const validators = state.validators();
    const balances = state.balances();
    const next_withdrawal_validator_index = state.nextWithdrawalValidatorIndex();

    // partial_withdrawals_count is withdrawals coming from EL since electra (EIP-7002)
    var processed_partial_withdrawals_count: u64 = 0;

    if (state.isPostElectra()) {
        // TODO: this optimization logic is not needed for TreeView
        // MAX_PENDING_PARTIALS_PER_WITHDRAWALS_SWEEP = 8, PENDING_PARTIAL_WITHDRAWALS_LIMIT: 134217728 so we should only call getAllReadonly() if it makes sense
        // pendingPartialWithdrawals comes from EIP-7002 smart contract where it takes fee so it's more likely than not validator is in correct condition to withdraw
        // also we may break early if withdrawableEpoch > epoch
        const pending_partial_withdrawals = state.pendingPartialWithdrawals();
        for (0..pending_partial_withdrawals.items.len) |i| {
            const withdrawal = pending_partial_withdrawals.items[i];
            if (withdrawal.withdrawable_epoch > epoch or withdrawals_result.withdrawals.items.len == preset.MAX_PENDING_PARTIALS_PER_WITHDRAWALS_SWEEP) {
                break;
            }

            const validator = validators.items[withdrawal.validator_index];
            const total_withdrawn_gop = try withdrawal_balances.getOrPut(withdrawal.validator_index);

            const total_withdrawn: u64 = if (total_withdrawn_gop.found_existing) total_withdrawn_gop.value_ptr.* else 0;
            const balance = balances.items[withdrawal.validator_index] - total_withdrawn;

            if (validator.exit_epoch == c.FAR_FUTURE_EPOCH and
                validator.effective_balance >= preset.MIN_ACTIVATION_BALANCE and
                balance > preset.MIN_ACTIVATION_BALANCE)
            {
                const balance_over_min_activation_balance = balance - preset.MIN_ACTIVATION_BALANCE;
                const withdrawable_balance = if (balance_over_min_activation_balance < withdrawal.amount) balance_over_min_activation_balance else withdrawal.amount;
                var execution_address: ExecutionAddress = undefined;
                std.mem.copyForwards(u8, &execution_address, validator.withdrawal_credentials[12..]);
                try withdrawals_result.withdrawals.append(allocator, .{
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
        const validator_index = (next_withdrawal_validator_index.* + n) % validators.items.len;
        const validator = validators.items[validator_index];
        const withdraw_balance_gop = try withdrawal_balances.getOrPut(validator_index);
        const withdraw_balance: u64 = if (withdraw_balance_gop.found_existing) withdraw_balance_gop.value_ptr.* else 0;
        const balance = if (state.isPostElectra())
            // Deduct partially withdrawn balance already queued above
            if (balances.items[validator_index] > withdraw_balance) balances.items[validator_index] - withdraw_balance else 0
        else
            balances.items[validator_index];

        const withdrawable_epoch = validator.withdrawable_epoch;
        const withdrawal_credentials = validator.withdrawal_credentials;
        const effective_balance = validator.effective_balance;
        const has_withdrawable_credentials = if (state.isPostElectra()) hasExecutionWithdrawalCredential(withdrawal_credentials) else hasEth1WithdrawalCredential(withdrawal_credentials);
        // early skip for balance = 0 as its now more likely that validator has exited/slashed with
        // balance zero than not have withdrawal credentials set
        if (balance == 0 or !has_withdrawable_credentials) {
            continue;
        }

        // capella full withdrawal
        if (withdrawable_epoch <= epoch) {
            var execution_address: ExecutionAddress = undefined;
            std.mem.copyForwards(u8, &execution_address, validator.withdrawal_credentials[12..]);
            try withdrawals_result.withdrawals.append(allocator, .{
                .index = withdrawal_index,
                .validator_index = validator_index,
                .address = execution_address,
                .amount = balance,
            });
            withdrawal_index += 1;
        } else if ((effective_balance == if (state.isPostElectra())
            getMaxEffectiveBalance(withdrawal_credentials)
        else
            preset.MAX_EFFECTIVE_BALANCE) and balance > effective_balance)
        {
            // capella partial withdrawal
            const partial_amount = balance - effective_balance;
            var execution_address: ExecutionAddress = undefined;
            std.mem.copyForwards(u8, &execution_address, validator.withdrawal_credentials[12..]);
            try withdrawals_result.withdrawals.append(allocator, .{
                .index = withdrawal_index,
                .validator_index = validator_index,
                .address = execution_address,
                .amount = partial_amount,
            });
            withdrawal_index += 1;
            try withdrawal_balances.put(validator_index, withdraw_balance + partial_amount);
        }

        // Break if we have enough to pack the block
        if (withdrawals_result.withdrawals.items.len >= preset.MAX_WITHDRAWALS_PER_PAYLOAD) {
            break;
        }
    }

    withdrawals_result.sampled_validators = n;
    withdrawals_result.processed_partial_withdrawals_count = processed_partial_withdrawals_count;
}
