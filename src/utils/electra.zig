const std = @import("std");
const params = @import("../params.zig");
const COMPOUNDING_WITHDRAWAL_PREFIX = params.COMPOUNDING_WITHDRAWAL_PREFIX;
const MIN_ACTIVATION_BALANCE = params.MIN_ACTIVATION_BALANCE;
const types = @import("../type.zig");
const WithdrawalCredentials = types.WithdrawalCredentials;
const BLSPubkey = types.BLSPubkey;
const ValidatorIndex = types.ValidatorIndex;
const PendingDeposit = types.PendingDeposit;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const hasEth1WithdrawalCredential = @import("./capella.zig").hasEth1WithdrawalCredential;

pub fn hasCompoundingWithdrawalCredential(withdrawal_credentials: WithdrawalCredentials) bool {
    return withdrawal_credentials[0] == COMPOUNDING_WITHDRAWAL_PREFIX;
}

pub fn hasExecutionWithdrawalCredential(withdrawal_credentials: WithdrawalCredentials) bool {
    return hasCompoundingWithdrawalCredential(withdrawal_credentials) or hasEth1WithdrawalCredential(withdrawal_credentials);
}

pub fn switchToCompoundingValidator(state_cache: *CachedBeaconStateAllForks, index: ValidatorIndex) !void {
    const validator = state_cache.state.getValidator(index);

    // directly modifying the byte leads to ssz missing the modification resulting into
    // wrong root compute, although slicing can be avoided but anyway this is not going
    // to be a hot path so its better to clean slice and avoid side effects
    const new_withdrawal_credentials = [_]u8{0} ** WithdrawalCredentials.length;
    std.mem.copyForwards(u8, new_withdrawal_credentials[0..], validator.withdrawal_credentials[0..]);
    new_withdrawal_credentials[0] = COMPOUNDING_WITHDRAWAL_PREFIX;
    validator.withdrawal_credentials = new_withdrawal_credentials;
    try queueExcessActiveBalance(state_cache, index);
}

pub fn queueExcessActiveBalance(cached_state: *CachedBeaconStateAllForks, index: ValidatorIndex) !void {
    const state = cached_state.state;
    const balance = state.getBalance(index);
    if (balance > MIN_ACTIVATION_BALANCE) {
        const validator = state.getValidator(index);
        const excess_balance = balance - MIN_ACTIVATION_BALANCE;
        state.setBalance(index, MIN_ACTIVATION_BALANCE);

        const pending_deposit = PendingDeposit{
            .pubkey = validator.pubkey,
            .withdrawal_credentials = validator.withdrawal_credentials,
            .amount = excess_balance,
            // Use bls.G2_POINT_AT_INFINITY as a signature field placeholder
            // TODO: define constant.zig
            .signature = G2_POINT_AT_INFINITY,
            //  Use GENESIS_SLOT to distinguish from a pending deposit request
            .slot = GENESIS_SLOT,
        };

        try state.pushPendingDeposit(pending_deposit);
    }
}

pub fn isPubkeyKnown(state: *const CachedBeaconStateAllForks, pubkey: BLSPubkey) bool {
    return isValidatorKnown(state, state.epoch_cache.getValidatorIndex(pubkey));
}

pub fn isValidatorKnown(state: *const CachedBeaconStateAllForks, index: ?ValidatorIndex) bool {
    const validator_index = index orelse return false;
    return validator_index < state.getValidatorCount();
}
