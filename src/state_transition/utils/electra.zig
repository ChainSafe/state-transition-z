const std = @import("std");
const params = @import("params");
const COMPOUNDING_WITHDRAWAL_PREFIX = params.COMPOUNDING_WITHDRAWAL_PREFIX;
const types = @import("../type.zig");
const ssz = @import("consensus_types");
const MIN_ACTIVATION_BALANCE = ssz.preset.MIN_ACTIVATION_BALANCE;

pub const WithdrawalCredentials = ssz.primitive.Root;
pub const WithdrawalCredentialsType = ssz.primitive.Root.Type;
const BLSPubkey = types.BLSPubkey;
const ValidatorIndex = types.ValidatorIndex;
const PendingDeposit = types.PendingDeposit;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const hasEth1WithdrawalCredential = @import("./capella.zig").hasEth1WithdrawalCredential;
const G2_POINT_AT_INFINITY = @import("../constants.zig").G2_POINT_AT_INFINITY;
const Allocator = std.mem.Allocator;

pub fn hasCompoundingWithdrawalCredential(withdrawal_credentials: WithdrawalCredentialsType) bool {
    return withdrawal_credentials[0] == COMPOUNDING_WITHDRAWAL_PREFIX;
}

pub fn hasExecutionWithdrawalCredential(withdrawal_credentials: WithdrawalCredentialsType) bool {
    return hasCompoundingWithdrawalCredential(withdrawal_credentials) or hasEth1WithdrawalCredential(withdrawal_credentials);
}

pub fn switchToCompoundingValidator(allocator: Allocator, state_cache: *CachedBeaconStateAllForks, index: ValidatorIndex) !void {
    const validator = state_cache.state.getValidator(index);

    // directly modifying the byte leads to ssz missing the modification resulting into
    // wrong root compute, although slicing can be avoided but anyway this is not going
    // to be a hot path so its better to clean slice and avoid side effects
    var new_withdrawal_credentials = [_]u8{0} ** WithdrawalCredentials.length;
    std.mem.copyForwards(u8, new_withdrawal_credentials[0..], validator.withdrawal_credentials[0..]);
    new_withdrawal_credentials[0] = COMPOUNDING_WITHDRAWAL_PREFIX;
    validator.withdrawal_credentials = new_withdrawal_credentials;
    try queueExcessActiveBalance(allocator, state_cache, index);
}

pub fn queueExcessActiveBalance(allocator: Allocator, cached_state: *CachedBeaconStateAllForks, index: ValidatorIndex) !void {
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
            .signature = G2_POINT_AT_INFINITY,
            //  Use GENESIS_SLOT to distinguish from a pending deposit request
            .slot = params.GENESIS_SLOT,
        };

        try state.pendingDeposits().append(allocator, pending_deposit);
    }
}

pub fn isPubkeyKnown(cached_state: *const CachedBeaconStateAllForks, pubkey: BLSPubkey) bool {
    return isValidatorKnown(cached_state.state, cached_state.getEpochCache().getValidatorIndex(&pubkey));
}

pub fn isValidatorKnown(state: *const BeaconStateAllForks, index: ?ValidatorIndex) bool {
    const validator_index = index orelse return false;
    return validator_index < state.getValidatorsCount();
}
