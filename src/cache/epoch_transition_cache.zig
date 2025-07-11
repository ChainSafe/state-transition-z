const std = @import("std");
const Allocator = std.mem.Allocator;
const types = @import("../type.zig");
const ValidatorIndex = types.ValidatorIndex;
const ValidatorIndices = types.ValidatorIndices;
const ForkSeq = types.ForkSeq;
const Epoch = types.Epoch;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const CachedBeaconStateAllForks = @import("./state_cache.zig").CachedBeaconStateAllForks;

const attester_status = @import("../utils/attester_status.zig");
const FLAG_CURR_HEAD_ATTESTER = attester_status.FLAG_CURR_HEAD_ATTESTER;
const FLAG_CURR_SOURCE_ATTESTER = attester_status.FLAG_CURR_SOURCE_ATTESTER;
const FLAG_CURR_TARGET_ATTESTER = attester_status.FLAG_CURR_TARGET_ATTESTER;
const FLAG_ELIGIBLE_ATTESTER = attester_status.FLAG_ELIGIBLE_ATTESTER;
const FLAG_PREV_HEAD_ATTESTER = attester_status.FLAG_PREV_HEAD_ATTESTER;
const FLAG_PREV_SOURCE_ATTESTER = attester_status.FLAG_PREV_SOURCE_ATTESTER;
const FLAG_PREV_TARGET_ATTESTER = attester_status.FLAG_PREV_TARGET_ATTESTER;
const FLAG_UNSLASHED = attester_status.FLAG_UNSLASHED;
const hasMarkers = attester_status.hasMarkers;

const params = @import("params");
const FAR_FUTURE_EPOCH = params.FAR_FUTURE_EPOCH;
const MIN_ACTIVATION_BALANCE = params.MIN_ACTIVATION_BALANCE;

const hasCompoundingWithdrawalCredential = @import("../utils/electra.zig").hasCompoundingWithdrawalCredential;
const computeBaseRewardPerIncrement = @import("../utils/altair.zig").computeBaseRewardPerIncrement;
const processPendingAttestations = @import("../epoch/process_pending_attestations.zig").processPendingAttestations;

const BoolArray = std.ArrayList(bool);
const UsizeArray = std.ArrayList(usize);
const U8Array = std.ArrayList(u8);
const U64Array = std.ArrayList(u64);
const U32Array = std.ArrayList(u32);

const ValidatorActivation = struct {
    validator_index: ValidatorIndex,
    activation_eligibility_epoch: Epoch,
};
const ValidatorActivationList = std.ArrayList(ValidatorActivation);

/// this is a cache that's never gc'd, it is used to store data that is reused across multiple epochs
pub const ReusedEpochTransitionCache = struct {
    is_active_prev_epoch: BoolArray,
    is_active_current_epoch: BoolArray,
    is_active_next_epoch: BoolArray,

    proposer_indices: UsizeArray,
    inclusion_delays: UsizeArray,

    flags: U8Array,

    // TODO: nextShufflingDecisionRoot, is it necessary without ShufflingCache?
    next_epoch_shuffling_active_validator_indices: ValidatorIndices,

    is_compounding_validator_arr: BoolArray,

    previous_epoch_participation: U8Array,
    current_epoch_participation: U8Array,
};

pub const EpochTransitionCache = struct {
    prev_epoch: Epoch,
    current_epoch: Epoch,
    total_active_stake_by_increment: u64,
    base_reward_per_increment: u64,
    prev_epoch_unslashed_stake_source_by_increment: u64,
    prev_epoch_unslashed_stake_target_by_increment: u64,
    prev_epoch_unslashed_stake_head_by_increment: u64,
    curr_epoch_unslashed_target_stake_by_increment: u64,
    indices_to_slash: ValidatorIndices,
    indices_eligible_for_activation_queue: ValidatorIndices,
    indices_eligible_for_activation: ValidatorIndices,
    indices_to_eject: ValidatorIndices,
    proposer_indices: UsizeArray,
    // phase0 only
    inclusion_delays: UsizeArray,
    flags: U8Array,
    is_compounding_validator_arr: BoolArray,
    balances: ?U64Array,
    next_shuffling_active_indices: []ValidatorIndex,
    // TODO: nextShufflingDecisionRoot may not needed as we don't use ShufflingCache
    next_epoch_total_active_balance_by_increment: u64,
    // TODO: asyncShufflingCalculation may not needed as we don't use ShufflingCache
    is_active_prev_epoch: BoolArray,
    is_active_curr_epoch: BoolArray,
    is_active_next_epoch: BoolArray,

    // TODO: no need EpochTransitionCacheOpts for zig version
    pub fn beforeProcessEpoch(allocator: Allocator, state_cache: *const CachedBeaconStateAllForks, reused_cache: *ReusedEpochTransitionCache) !EpochTransitionCache {
        const config = state_cache.config;
        const epoch_cache = state_cache.epoch_cache;
        const state = state_cache.state;
        const fork_seq = config.getForkSeq(state.getSlot());
        const current_epoch = epoch_cache.epoch;
        const prev_epoch = epoch_cache.previous_shuffling.epoch;
        const next_epoch = current_epoch + 1;
        // active validator indices for nextShuffling is ready, we want to precalculate for the one after that
        const next_epoch_2 = current_epoch + 2;

        const slashings_epoch = current_epoch + @divFloor(preset.EPOCHS_PER_SLASHINGS_VECTOR, 2);

        const indices_to_slash = ValidatorIndices.init(allocator);
        const indices_eligible_for_activation_queue = ValidatorIndices.init(allocator);
        // we will extract indices_eligible_for_activation from validator_activation_list later
        const validator_activation_list = ValidatorActivationList.init(allocator);
        const indices_to_eject = ValidatorIndices.init(allocator);

        var total_active_stake_by_increment: u64 = 0;
        const validator_count = state.getValidatorCount();
        try reused_cache.next_epoch_shuffling_active_validator_indices.ensureTotalCapacity(validator_count);
        var next_epoch_shuffling_active_indices_length: usize = 0;
        // pre-fill with true (most validators are active)
        try reused_cache.is_active_prev_epoch.resize(validator_count);
        try reused_cache.is_active_current_epoch.resize(validator_count);
        try reused_cache.is_active_next_epoch.resize(validator_count);
        @memset(reused_cache.is_active_prev_epoch.items, true);
        @memset(reused_cache.is_active_current_epoch.items, true);
        @memset(reused_cache.is_active_next_epoch.items, true);

        // During the epoch transition, additional data is precomputed to avoid traversing any state a second
        // time. Attestations are a big part of this, and each validator has a "status" to represent its
        // precomputed participation.
        // - proposerIndex: number; // -1 when not included by any proposer, for phase0 only so it's declared inside phase0 block below
        // - inclusionDelay: number;// for phase0 only so it's declared inside phase0 block below
        // - flags: number; // bitfield of AttesterFlags
        try reused_cache.flags.ensureTotalCapacity(validator_count);
        // flags.fill(0);
        // flags will be zero'd out below
        // In the first loop, set slashed+eligibility
        // In the second loop, set participation flags
        // TODO: optimize by combining the two loops
        // likely will require splitting into phase0 and post-phase0 versions

        if (fork_seq >= ForkSeq.electra) {
            try reused_cache.is_compounding_validator_arr.ensureTotalCapacity(validator_count);
        }

        // Clone before being mutated in processEffectiveBalanceUpdates
        epoch_cache.beforeEpochTransition();

        const effective_balances_by_increments = epoch_cache.effective_balance_increments;

        for (0..validator_count) |i| {
            const validator = state.getValidator(i);
            var flag: u8 = 0;

            if (validator.slashed) {
                if (slashings_epoch == validator.withdrawable_epoch) {
                    try indices_to_slash.append(i);
                }
            } else {
                flag |= FLAG_UNSLASHED;
            }

            const activation_epoch = validator.activation_epoch;
            const exit_epoch = validator.exit_epoch;
            const is_active_prev: bool = activation_epoch <= prev_epoch and prev_epoch < exit_epoch;
            const is_active_curr = activation_epoch <= current_epoch and current_epoch < exit_epoch;
            const is_active_next = activation_epoch <= next_epoch and next_epoch < exit_epoch;
            const is_active_next_2 = activation_epoch <= next_epoch_2 and next_epoch_2 < exit_epoch;

            if (!is_active_prev) {
                reused_cache.is_active_prev_epoch.items[i] = false;
            }

            // Both active validators and slashed-but-not-yet-withdrawn validators are eligible to receive penalties.
            // This is done to prevent self-slashing from being a way to escape inactivity leaks.
            // TODO: Consider using an array of `eligibleValidatorIndices: number[]`
            if (is_active_prev || (validator.slashed and prev_epoch + 1 < validator.withdrawable_epoch)) {
                flag |= FLAG_ELIGIBLE_ATTESTER;
            }

            reused_cache.flags[i] = flag;

            if (fork_seq >= ForkSeq.electra) {
                reused_cache.is_compounding_validator_arr.items[i] = hasCompoundingWithdrawalCredential(validator.withdrawal_credentials);
            }

            if (is_active_curr) {
                total_active_stake_by_increment += effective_balances_by_increments[i];
            } else {
                reused_cache.is_active_curr_epoch.items[i] = false;
            }

            // To optimize process_registry_updates():
            // ```python
            // def is_eligible_for_activation_queue(validator: Validator) -> bool:
            //   return (
            //     validator.activation_eligibility_epoch == FAR_FUTURE_EPOCH
            //     and validator.effective_balance >= MAX_EFFECTIVE_BALANCE # [Modified in Electra]
            //   )
            // ```
            if (validator.activation_eligibility_epoch == FAR_FUTURE_EPOCH and validator.effective_balance >= MIN_ACTIVATION_BALANCE) {
                try indices_eligible_for_activation_queue.append(i);
            }

            // To optimize process_registry_updates():
            // ```python
            // def is_eligible_for_activation(state: BeaconState, validator: Validator) -> bool:
            //   return (
            //     validator.activation_eligibility_epoch <= state.finalized_checkpoint.epoch  # Placement in queue is finalized
            //     and validator.activation_epoch == FAR_FUTURE_EPOCH                          # Has not yet been activated
            //   )
            // ```
            // Here we have to check if `activationEligibilityEpoch <= currentEpoch` instead of finalized checkpoint, because the finalized
            // checkpoint may change during epoch processing at processJustificationAndFinalization(), which is called before processRegistryUpdates().
            // Then in processRegistryUpdates() we will check `activationEligibilityEpoch <= finalityEpoch`. This is to keep the array small.
            //
            // Use `else` since indicesEligibleForActivationQueue + indicesEligibleForActivation are mutually exclusive
            else if (validator.activation_epoch == FAR_FUTURE_EPOCH and validator.activation_eligibility_epoch <= current_epoch) {
                try validator_activation_list.append(.{
                    .validator_index = i,
                    .activation_eligibility_epoch = validator.activation_eligibility_epoch,
                });
            }

            // To optimize process_registry_updates():
            // ```python
            // if is_active_validator(validator, get_current_epoch(state)) and validator.effective_balance <= EJECTION_BALANCE:
            // ```
            // Adding extra condition `exitEpoch === FAR_FUTURE_EPOCH` to keep the array as small as possible. initiateValidatorExit() will ignore them anyway
            //
            // Use `else` since indicesEligibleForActivationQueue + indicesEligibleForActivation + indicesToEject are mutually exclusive
            else if (is_active_curr and validator.exit_epoch == FAR_FUTURE_EPOCH and validator.effective_balance <= config.chain.EJECTION_BALANCE) {
                try indices_to_eject.append(i);
            }

            if (!is_active_next) {
                reused_cache.is_active_next_epoch.items[i] = false;
            }

            if (is_active_next_2) {
                reused_cache.next_epoch_shuffling_active_validator_indices.items[next_epoch_shuffling_active_indices_length] = i;
                next_epoch_shuffling_active_indices_length += 1;
            }
        } // end validator loop

        // no need to trigger async build as zig should be fast enough

        // typescript: only the first `activeValidatorCount` elements are copied to `activeIndices`
        // here in zig we simply return a slice, consumer only borrows this slice and need to allocate a separate array for the next shuffling computation
        const next_shuffling_active_indices = reused_cache.next_epoch_shuffling_active_validator_indices[0..next_epoch_shuffling_active_indices_length];

        if (total_active_stake_by_increment < 1) {
            total_active_stake_by_increment = 1;
        }

        // SPEC: function getBaseRewardPerIncrement()
        const base_reward_per_increment = computeBaseRewardPerIncrement(total_active_stake_by_increment);

        // To optimize process_registry_updates():
        // order by sequence of activationEligibilityEpoch setting and then index
        const sort_fn = struct {
            pub fn sort(_: anytype, a: ValidatorActivation, b: ValidatorActivation) bool {
                // sort by activationEligibilityEpoch first, then by index
                if (a.activation_eligibility_epoch != b.activation_eligibility_epoch) {
                    return a.activation_eligibility_epoch < b.activation_eligibility_epoch;
                }
                return a.validator_index < b.validator_index;
            }
        }.sort;
        std.mem.sort(ValidatorActivation, validator_activation_list.items, {}, sort_fn);

        if (fork_seq == ForkSeq.phase0) {
            reused_cache.proposer_indices.resize(validator_count);
            // in typescript we prefill with -1 as unset value, in zig we use  validator_count
            @memset(reused_cache.proposer_indices.items, validator_count);
            reused_cache.inclusion_delays.resize(validator_count);
            @memset(reused_cache.inclusion_delays.items, 0);
            try processPendingAttestations(state, reused_cache.proposer_indices, validator_count, reused_cache.inclusion_delays, reused_cache.flags, state.getPreviousEpochPendingAttestations(), prev_epoch, FLAG_PREV_SOURCE_ATTESTER, FLAG_PREV_TARGET_ATTESTER, FLAG_PREV_HEAD_ATTESTER);
            try processPendingAttestations(state, reused_cache.proposer_indices, validator_count, reused_cache.inclusion_delays, reused_cache.flags, state.getCurrentEpochPendingAttestations(), current_epoch, FLAG_CURR_SOURCE_ATTESTER, FLAG_CURR_TARGET_ATTESTER, FLAG_CURR_HEAD_ATTESTER);
        } else {
            reused_cache.previous_epoch_participation.ensureTotalCapacity(validator_count);
            reused_cache.current_epoch_participation.ensureTotalCapacity(validator_count);
            // TODO: does not work for TreeView
            @memcpy(reused_cache.previous_epoch_participation.items[0..validator_count], state.getPreviousEpochParticipations());
            @memcpy(reused_cache.current_epoch_participation, state.getCurrentEpochParticipations());
            for (0..validator_count) |i| {
                reused_cache.flags[i] |=
                    // checking active status first is required to pass random spec tests in altair
                    // in practice, inactive validators will have 0 participation
                    // FLAG_PREV are indexes [0,1,2]
                    (if (reused_cache.is_active_prev_epoch[i]) reused_cache.previous_epoch_participation.items[i] else 0) |
                    // FLAG_CURR are indexes [3,4,5], so shift by 3
                    (if (reused_cache.is_active_current_epoch[i]) reused_cache.current_epoch_participation.items[i] << 3 else 0);
            }
        }

        var prev_source_unsl_stake: u64 = 0;
        var prev_target_unsl_stake: u64 = 0;
        var prev_head_unsl_stake: u64 = 0;

        var curr_target_unsl_stake: u64 = 0;

        const FLAG_PREV_SOURCE_ATTESTER_UNSLASHED = FLAG_PREV_SOURCE_ATTESTER | FLAG_UNSLASHED;
        const FLAG_PREV_TARGET_ATTESTER_UNSLASHED = FLAG_PREV_TARGET_ATTESTER | FLAG_UNSLASHED;
        const FLAG_PREV_HEAD_ATTESTER_UNSLASHED = FLAG_PREV_HEAD_ATTESTER | FLAG_UNSLASHED;
        const FLAG_CURR_TARGET_UNSLASHED = FLAG_CURR_TARGET_ATTESTER | FLAG_UNSLASHED;

        for (0..validator_count) |i| {
            const effective_balance_by_increment = effective_balances_by_increments[i];
            const flag = reused_cache.flags[i];
            if (hasMarkers(flag, FLAG_PREV_SOURCE_ATTESTER_UNSLASHED)) {
                prev_source_unsl_stake += effective_balance_by_increment;
            }
            if (hasMarkers(flag, FLAG_PREV_TARGET_ATTESTER_UNSLASHED)) {
                prev_target_unsl_stake += effective_balance_by_increment;
            }
            if (hasMarkers(flag, FLAG_PREV_HEAD_ATTESTER_UNSLASHED)) {
                prev_head_unsl_stake += effective_balance_by_increment;
            }
            if (hasMarkers(flag, FLAG_CURR_TARGET_UNSLASHED)) {
                curr_target_unsl_stake += effective_balance_by_increment;
            }
        }

        // assertCorrectProgressiveBalances = true by default
        if (fork_seq >= ForkSeq.altair) {
            if (epoch_cache.current_target_unslashed_balance_increments != curr_target_unsl_stake) {
                return error.InCorrectCurrentTargetUnslashedBalance;
            }
            if (epoch_cache.previous_target_unslashed_balance_increments != prev_target_unsl_stake) {
                return error.InCorrectPreviousTargetUnslashedBalance;
            }
        }

        // As per spec of `get_total_balance`:
        // EFFECTIVE_BALANCE_INCREMENT Gwei minimum to avoid divisions by zero.
        // Math safe up to ~10B ETH, afterwhich this overflows uint64.
        if (prev_source_unsl_stake < 1) {
            prev_source_unsl_stake = 1;
        }
        if (prev_target_unsl_stake < 1) {
            prev_target_unsl_stake = 1;
        }
        if (prev_head_unsl_stake < 1) {
            prev_head_unsl_stake = 1;
        }
        if (curr_target_unsl_stake < 1) {
            curr_target_unsl_stake = 1;
        }

        // zig specific map function similar to "indicesEligibleForActivation.map(({validatorIndex}) => validatorIndex)"
        const indices_eligible_for_activation = ValidatorIndices.init(allocator);
        for (validator_activation_list.items) |activation| {
            try indices_eligible_for_activation.append(activation.validator_index);
        }

        return .{
            .prev_epoch = prev_epoch,
            .current_epoch = current_epoch,
            .total_active_stake_by_increment = total_active_stake_by_increment,
            .base_reward_per_increment = base_reward_per_increment,
            .prev_epoch_unslashed_stake_source = prev_source_unsl_stake,
            .prev_epoch_unslashed_stake_target = prev_target_unsl_stake,
            .prev_epoch_unslashed_stake_head = prev_head_unsl_stake,
            .curr_epoch_unslashed_target_stake_by_increment = curr_target_unsl_stake,
            .indices_to_slash = indices_to_slash,
            .indices_eligible_for_activation_queue = indices_eligible_for_activation_queue,
            .indices_eligible_for_activation = indices_eligible_for_activation,
            .indices_to_eject = indices_to_eject,
            .next_shuffling_active_indices = next_shuffling_active_indices,
            // to be updated in processEffectiveBalanceUpdates
            .next_epoch_total_active_balance_by_increment = 0,
            .is_active_prev_epoch = reused_cache.is_active_prev_epoch,
            .is_active_curr_epoch = reused_cache.is_active_current_epoch,
            .proposer_indices = reused_cache.proposer_indices,
            .inclusion_delays = reused_cache.inclusion_delays,
            .flags = reused_cache.flags,
            .is_compounding_validator_arr = reused_cache.is_compounding_validator_arr,
            // Will be assigned in processRewardsAndPenalties()
            .balances = null,
        };
    }

    pub fn deinit(self: *EpochTransitionCache) void {
        // no need to deinit proposer_indices and inclusion_delays as they are from reused_cache
        self.flags.deinit();
        // no need to deinit below as they are from reused_cache
        // self.is_active_prev_epoch.deinit();
        // self.is_active_curr_epoch.deinit();
        // self.is_active_next_epoch.deinit();
        // self.is_compounding_validator_arr.deinit();
        self.indices_to_slash.deinit();
        self.indices_eligible_for_activation_queue.deinit();
        self.indices_eligible_for_activation.deinit();
        self.indices_to_eject.deinit();
        if (self.balances) |balances| {
            balances.deinit();
        }
    }
};

// TODO: unit tests
