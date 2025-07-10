const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const Root = ssz.primitive.Root.Type;
const SignedBLSToExecutionChange = ssz.capella.SignedBLSToExecutionChange.Type;
const params = @import("../params.zig");
const digest = @import("../utils/sha256.zig").digest;
const verifyBlsToExecutionChangeSignature = @import("../signature_sets/bls_to_execution_change.zig").verifyBlsToExecutionChangeSignature;

pub fn processBlsToExecutionChange(state: *CachedBeaconStateAllForks, signed_bls_to_execution_change: *const SignedBLSToExecutionChange) !void {
    const address_change = signed_bls_to_execution_change.message;

    try isValidBlsToExecutionChange(state, signed_bls_to_execution_change, true);

    const validator_index = address_change.validator_index;
    const validator = state.state.getValidator(validator_index);
    const new_withdrawal_credentials = address_change.to_execution_address;
    new_withdrawal_credentials[0] = params.ETH1_ADDRESS_WITHDRAWAL_PREFIX;
    @memcpy(new_withdrawal_credentials[12..], &address_change.to_execution_address);

    // Set the new credentials back
    validator.withdrawal_credentials = new_withdrawal_credentials;
}

pub fn isValidBlsToExecutionChange(cached_state: *CachedBeaconStateAllForks, signed_bls_to_execution_change: *const SignedBLSToExecutionChange, verify_signature: ?bool) !void {
    const state = cached_state.state;
    const address_change = signed_bls_to_execution_change.message;
    const validator_index = address_change.validator_index;
    if (validator_index >= state.getValidatorsCount()) {
        return error.InvalidBlsToExecutionChange;
    }

    const validator = state.getValidator(validator_index);
    const withdrawal_credentials = validator.withdrawal_credentials;
    if (withdrawal_credentials[0] != params.BLS_WITHDRAWAL_PREFIX) {
        return error.InvalidWithdrawalCredentialsPrefix;
    }

    var digest_credentials: Root = undefined;
    digest(address_change.from_bls_pubkey, &digest_credentials);
    // Set the BLS_WITHDRAWAL_PREFIX on the digest_credentials for direct match
    digest_credentials[0] = params.BLS_WITHDRAWAL_PREFIX;
    if (!std.mem.eql(u8, &withdrawal_credentials, &digest_credentials)) {
        return error.InvalidWithdrawalCredentials;
    }

    if (verify_signature orelse true) {
        if (!verifyBlsToExecutionChangeSignature(cached_state, signed_bls_to_execution_change)) {
            return error.InvalidBlsToExecutionChangeSignature;
        }
    }
}
