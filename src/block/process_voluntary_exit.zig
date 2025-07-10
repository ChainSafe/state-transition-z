const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const SignedVoluntaryExit = ssz.phase0.SignedVoluntaryExit.Type;
const isActiveValidator = @import("../utils/validator.zig").isActiveValidator;
const getPendingBalanceToWithdraw = @import("../utils/validator.zig").getPendingBalanceToWithdraw;
const verifyVoluntaryExitSignature = @import("../signature_sets/voluntary_exits.zig").verifyVoluntaryExitSignature;
const initiateValidatorExit = @import("./initiate_validator_exit.zig").initiateValidatorExit;

pub fn processVoluntaryExit(cached_state: *CachedBeaconStateAllForks, signed_voluntary_exit: *const SignedVoluntaryExit, verify_signature: ?bool) !void {
    if (!isValidVoluntaryExit(cached_state, signed_voluntary_exit, verify_signature)) {
        return error.InvalidVoluntaryExit;
    }

    const validator = cached_state.state.getValidator(signed_voluntary_exit.message.validator_index);
    initiateValidatorExit(cached_state, validator);
}

pub fn isValidVoluntaryExit(cached_state: *CachedBeaconStateAllForks, signed_voluntary_exit: *const SignedVoluntaryExit, verify_signature: ?bool) bool {
    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;
    const voluntary_exit = signed_voluntary_exit.message;
    const validator = state.getValidator(voluntary_exit.validator_index);
    const current_epoch = epoch_cache.epoch;

    return (
        // verify the validator is active
        isActiveValidator(validator, current_epoch) and
            // verify exit has not been initiated
            validator.exit_epoch == ssz.phase0.FAR_FUTURE_EPOCH and
            // exits must specify an epoch when they become valid; they are not valid before then
            current_epoch >= voluntary_exit.epoch and
            // verify the validator had been active long enough
            current_epoch >= validator.activation_epoch + state.config.SHARD_COMMITTEE_PERIOD and
            (if (state.isPostElectra()) getPendingBalanceToWithdraw(cached_state, voluntary_exit.validator_index) == 0 else true) and
            // verify signature
            (if (verify_signature orelse true) verifyVoluntaryExitSignature(cached_state, signed_voluntary_exit) else true));
}

// TODO: unit test
