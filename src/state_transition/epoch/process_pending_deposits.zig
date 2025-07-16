const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const getActivationExitChurnLimit = @import("../utils/validator.zig").getActivationExitChurnLimit;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const isValidatorKnown = @import("../utils/electra.zig").isValidatorKnown;
const ForkSeq = @import("params").ForkSeq;
const isValidDepositSignature = @import("../block/process_deposit.zig").isValidDepositSignature;
const addValidatorToRegistry = @import("../block/process_deposit.zig").addValidatorToRegistry;
const hasCompoundingWithdrawalCredential = @import("../utils/electra.zig").hasCompoundingWithdrawalCredential;
const increaseBalance = @import("../utils/balance.zig").increaseBalance;
const computeStartSlotAtEpoch = @import("../utils/epoch.zig").computeStartSlotAtEpoch;
const types = @import("../type.zig");
const PendingDeposit = types.PendingDeposit;
const params = @import("params");

pub fn processPendingDeposits(cached_state: *CachedBeaconStateAllForks, cache: *const EpochTransitionCache) !void {
    const epoch_cache = cached_state.getEpochCache();
    const state = cached_state.state;
    const next_epoch = epoch_cache.epoch + 1;
    const available_for_processing = state.getDepositBalanceToConsume() + getActivationExitChurnLimit(epoch_cache);
    var processed_amount: u64 = 0;
    var next_deposit_index: u64 = 0;
    var is_churn_limit_reached = false;
    const finalized_slot = computeStartSlotAtEpoch(state.getFinalizedCheckpoint().epoch);

    var start_index: usize = 0;
    // TODO: is this a good number?
    const chunk = 100;
    const pending_deposits_len = state.getPendingDepositCount();
    outer: while (start_index < pending_deposits_len) : (start_index += chunk) {
        // TODO(ssz): implement getReadonlyByRange api for TreeView
        // const deposits: []PendingDeposit = state.getPendingDeposits().getReadonlyByRange(start_index, chunk);
        const deposits: []PendingDeposit = state.getPendingDeposits()[start_index..@min(start_index + chunk, pending_deposits_len)];
        for (deposits) |deposit| {
            // Do not process deposit requests if Eth1 bridge deposits are not yet applied.
            if (
            // Is deposit request
            deposit.slot > params.GENESIS_SLOT and
                // There are pending Eth1 bridge deposits
                state.getEth1DepositIndex() < state.getDepositRequestsStartIndex())
            {
                break :outer;
            }

            // Check if deposit has been finalized, otherwise, stop processing.
            if (deposit.slot > finalized_slot) {
                break :outer;
            }

            // Check if number of processed deposits has not reached the limit, otherwise, stop processing.
            // TODO(ssz): define MAX_PENDING_DEPOSITS_PER_EPOCH in preset
            const MAX_PENDING_DEPOSITS_PER_EPOCH = 16;
            if (next_deposit_index >= MAX_PENDING_DEPOSITS_PER_EPOCH) {
                break :outer;
            }

            // Read validator state
            var is_validator_exited = false;
            var is_validator_withdrawn = false;
            const validator_index = epoch_cache.getValidatorIndex(&deposit.pubkey);

            if (isValidatorKnown(state, validator_index)) {
                const validator = state.getValidator(validator_index.?);
                is_validator_exited = validator.exit_epoch < params.FAR_FUTURE_EPOCH;
                is_validator_withdrawn = validator.withdrawable_epoch < next_epoch;
            }

            if (is_validator_withdrawn) {
                // Deposited balance will never become active. Increase balance but do not consume churn
                try applyPendingDeposit(state, deposit, cache);
            } else if (is_validator_exited) {
                // TODO: typescript version accumulate to temp array while in zig we append directly
                state.addPendingDeposit(deposit);
            } else {
                // Check if deposit fits in the churn, otherwise, do no more deposit processing in this epoch.
                is_churn_limit_reached = processed_amount + deposit.amount > available_for_processing;
                if (is_churn_limit_reached) {
                    break :outer;
                }
                // Consume churn and apply deposit.
                processed_amount += deposit.amount;
                try applyPendingDeposit(state, deposit, cache);
            }

            // Regardless of how the deposit was handled, we move on in the queue.
            next_deposit_index += 1;
        }
    }

    const remaining_pending_deposits = try state.sliceFromPendingDeposits(next_deposit_index);
    state.setPendingDeposits(remaining_pending_deposits);

    // TODO: consider doing this for TreeView
    //   for (const deposit of depositsToPostpone) {
    //   state.pendingDeposits.push(deposit);
    // }

    // no need to append to pending_deposits again because we did that in the for loop above already
    // Accumulate churn only if the churn limit has been hit.
    if (is_churn_limit_reached) {
        state.setDepositBalanceToConsume(available_for_processing - processed_amount);
    } else {
        state.setDepositBalanceToConsume(0);
    }
}

fn applyPendingDeposit(cached_state: *CachedBeaconStateAllForks, deposit: PendingDeposit, cache: *const EpochTransitionCache) !void {
    const epoch_cache = cached_state.getEpochCache();
    const state = cached_state.state;
    const validator_index = epoch_cache.getValidatorIndex(deposit.pubkey);
    const pubkey = deposit.pubkey;
    const withdrawal_credential = deposit.withdrawal_credential;
    const amount = deposit.amount;
    const signature = deposit.signature;
    const is_validator_known = isValidatorKnown(cached_state, validator_index);

    if (!is_validator_known) {
        // Verify the deposit signature (proof of possession) which is not checked by the deposit contract
        if (try isValidDepositSignature(cached_state.config, pubkey, withdrawal_credential, amount, signature)) {
            try addValidatorToRegistry(ForkSeq.electra, state, pubkey, withdrawal_credential, amount);
        }

        if (isValidDepositSignature(state.config, pubkey, withdrawal_credential, amount, signature)) {
            try addValidatorToRegistry(ForkSeq.electra, state, pubkey, withdrawal_credential, amount);
            cache.is_compounding_validator_arr.append(hasCompoundingWithdrawalCredential(withdrawal_credential));
            // set balance, so that the next deposit of same pubkey will increase the balance correctly
            // this is to fix the double deposit issue found in mekong
            // see https://github.com/ChainSafe/lodestar/pull/7255
            if (cache.balances) |balances| {
                try balances.append(amount);
            }
        }
    } else {
        // Increase balance
        increaseBalance(state, validator_index, amount);
        if (cache.balances) |balances| {
            balances[validator_index] += amount;
        }
    }
}
