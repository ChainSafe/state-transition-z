const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const params = @import("../params.zig");
const blst = @import("blst_min_pk");
const Epoch = ssz.primitive.Epoch.Type;
const Slot = ssz.primitive.Slot.Type;
const Publickey = ssz.primitive.BLSPubkey.Type;
const BLSSignature = ssz.primitive.BLSSignature.Type;
const BLSPubkey = blst.PublicKey;
const SyncPeriod = ssz.primitive.SyncPeriod.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const CommitteeIndex = ssz.primitive.CommitteeIndex.Type;
const ForkSeq = @import("../config.zig").ForkSeq;
const BeaconConfig = @import("../config.zig").BeaconConfig;
const PubkeyIndexMap = @import("../utils/pubkey_index_map.zig").PubkeyIndexMap;
const Index2PubkeyCache = @import("./pubkey_cache.zig").Index2PubkeyCache;
const EpochShuffling = @import("../utils//epoch_shuffling.zig").EpochShuffling;
const EpochShufflingRc = @import("../utils/epoch_shuffling.zig").EpochShufflingRc;
const EffectiveBalanceIncrementsRc = @import("./effective_balance_increments.zig").EffectiveBalanceIncrementsRc;
const EffectiveBalanceIncrements = @import("./effective_balance_increments.zig").EffectiveBalanceIncrements;
const BeaconStateAllForks = @import("../beacon_state.zig").BeaconStateAllForks;
const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;
const computeActivationExitEpoch = @import("../utils/epoch.zig").computeActivationExitEpoch;
const getEffectiveBalanceIncrementsWithLen = @import("./effective_balance_increments.zig").getEffectiveBalanceIncrementsWithLen;
const getTotalSlashingsByIncrement = @import("../epoch/process_slashings.zig").getTotalSlashingsByIncrement;
const computeEpochShuffling = @import("../utils/epoch_shuffling.zig").computeEpochShuffling;
const getSeed = @import("../utils/seed.zig").getSeed;
const computeProposers = @import("../utils/seed.zig").computeProposers;
const SyncCommitteeCacheRc = @import("./sync_committee_cache.zig").SyncCommitteeCacheRc;
const SyncCommitteeCacheAllForks = @import("./sync_committee_cache.zig").SyncCommitteeCacheAllForks;
const computeSyncParticipantReward = @import("../utils/sync_committee.zig").computeSyncParticipantReward;
const computeBaseRewardPerIncrement = @import("../utils/sync_committee.zig").computeBaseRewardPerIncrement;
const computeSyncPeriodAtEpoch = @import("../utils/epoch.zig").computeSyncPeriodAtEpoch;
const isAggregatorFromCommitteeLength = @import("../utils/aggregator.zig").isAggregatorFromCommitteeLength;

const sumTargetUnslashedBalanceIncrements = @import("../utils/target_unslashed_balance.zig").sumTargetUnslashedBalanceIncrements;

const ValidatorIndices = @import("../type.zig").ValidatorIndices;
const isActiveValidator = @import("../utils/validator.zig").isActiveValidator;
const getChurnLimit = @import("../utils/validator.zig").getChurnLimit;
const getActivationChurnLimit = @import("../utils/validator.zig").getActivationChurnLimit;

pub const EpochCacheImmutableData = struct {
    config: *BeaconConfig,
    pubkey_to_index: PubkeyIndexMap,
    index_to_pubkey: Index2PubkeyCache,
};

pub const EpochCacheOpts = struct {
    skip_sync_committee_cache: bool,
    skip_sync_pubkeys: bool,
};

pub const PROPOSER_WEIGHT_FACTOR = params.PROPOSER_WEIGHT / (params.WEIGHT_DENOMINATOR - params.PROPOSER_WEIGHT);

pub const EpochCache = struct {
    allocator: Allocator,

    config: *BeaconConfig,

    // this is shared across applications, EpochCache does not own this field so should not deinit()
    pubkey_to_index: PubkeyIndexMap,

    // this is shared across applications, EpochCache does not own this field so should not deinit()
    index_to_pubkey: Index2PubkeyCache,

    proposers: [preset.SLOTS_PER_EPOCH]u32,

    proposer_prev_epoch: ?[preset.SLOTS_PER_EPOCH]u32,

    // TODO: may not need this
    // proposers_next_epoch
    // the below is not needed if we compute the next epoch shuffling eagerly
    // previous_decision_root
    // current_decision_root
    // next_decision_root

    // EpochCache does not take ownership of EpochShuffling, it is shared across EpochCache instances
    previous_shuffling: EpochShufflingRc,

    current_shuffling: EpochShufflingRc,

    next_shuffling: EpochShufflingRc,

    // this is not needed if we compute next_shuffling eagerly
    // next_active_indices

    // EpochCache does not take ownership of EffectiveBalanceIncrements, it is shared across EpochCache instances
    effective_balance_increment: EffectiveBalanceIncrementsRc,

    total_slashings_by_increment: u64,

    sync_participant_reward: u64,

    sync_proposer_reward: u64,

    base_reward_per_increment: u64,

    total_acrive_balance_increments: u64,

    churn_limit: u64,

    activation_churn_limit: u64,

    exit_queue_epoch: Epoch,

    exit_queue_churn: u64,

    current_target_unslashed_balance_increments: u64,

    previous_target_unslashed_balance_increments: u64,

    // EpochCache does not take ownership of SyncCommitteeCache, it is shared across EpochCache instances
    current_sync_committee_indexed: SyncCommitteeCacheRc,

    next_sync_committee_indexed: SyncCommitteeCacheRc,

    sync_period: SyncPeriod,

    epoch: Epoch,

    next_epoch: Epoch,

    pub fn createFromState(allocator: Allocator, state: *const BeaconStateAllForks, immutable_data: EpochCacheImmutableData, option: ?EpochCacheOpts) !*EpochCache {
        const config = immutable_data.config;
        const pubkey_to_index = immutable_data.pubkey_to_index;
        const index_to_pubkey = immutable_data.index_to_pubkey;

        const current_epoch = computeEpochAtSlot(state.getSlot());
        const is_genesis = current_epoch == params.GENESIS_EPOCH;
        const previous_epoch = if (is_genesis) params.GENESIS_EPOCH else current_epoch - 1;
        const next_epoch = current_epoch + 1;

        var total_active_balance_increments: u64 = 0;
        var exit_queue_epoch = computeActivationExitEpoch(current_epoch);
        var exit_queue_churn: u64 = 0;

        const validators = state.getValidators();
        const validator_count = state.getValidatorCount();

        // syncPubkeys here to ensure EpochCacheImmutableData is popualted before computing the rest of caches
        // - computeSyncCommitteeCache() needs a fully populated pubkey2index cache
        const skip_sync_pubkeys = if (option) |opt| opt.skip_sync_pubkeys else false;
        if (!skip_sync_pubkeys) {
            pubkey_to_index.ensureSyncPubkeys(allocator, state, config);
        }

        const effective_balance_increment = getEffectiveBalanceIncrementsWithLen(allocator, validator_count);
        const total_slashings_by_increment = getTotalSlashingsByIncrement(state);
        const previous_active_indices_as_number_array = ValidatorIndices.init(allocator);
        previous_active_indices_as_number_array.ensureTotalCapacity(validator_count);
        const current_active_indices_as_number_array = ValidatorIndices.init(allocator);
        current_active_indices_as_number_array.ensureTotalCapacity(validator_count);
        const next_active_indices_as_number_array = ValidatorIndices.init(allocator);
        next_active_indices_as_number_array.ensureTotalCapacity(validator_count);

        for (0..validator_count) |i| {
            const validator = state.getValidator(i);

            // Note: Not usable for fork-choice balances since in-active validators are not zero'ed
            effective_balance_increment.items[i] = @divFloor(validator.effective_balance, preset.EFFECTIVE_BALANCE_INCREMENT);

            if (isActiveValidator(validator, previous_epoch)) {
                try previous_active_indices_as_number_array.append(i);
            }

            if (isActiveValidator(validator, current_epoch)) {
                try current_active_indices_as_number_array.append(i);
                total_active_balance_increments += effective_balance_increment.items[i];
            }

            if (isActiveValidator(validator, next_epoch)) {
                try next_active_indices_as_number_array.append(i);
            }

            const exit_epoch = validator.exit_epoch;
            if (exit_epoch != params.FAR_FUTURE_EPOCH) {
                if (exit_epoch > exit_queue_epoch) {
                    exit_queue_epoch = exit_epoch;
                    exit_queue_churn = 1;
                } else if (exit_epoch == exit_queue_epoch) {
                    exit_queue_churn += 1;
                }
            }
        }

        // Spec: `EFFECTIVE_BALANCE_INCREMENT` Gwei minimum to avoid divisions by zero
        // 1 = 1 unit of EFFECTIVE_BALANCE_INCREMENT
        if (total_active_balance_increments < 1) {
            total_active_balance_increments = 1;
        }

        const previous_shuffling: EpochShuffling = try computeEpochShuffling(allocator, state, previous_active_indices_as_number_array, previous_epoch);
        const current_shuffling: EpochShuffling = try computeEpochShuffling(allocator, state, current_active_indices_as_number_array, current_epoch);
        const next_shuffling: EpochShuffling = try computeEpochShuffling(allocator, state, next_active_indices_as_number_array, next_epoch);

        // TODO: implement proposerLookahead in fulu
        const fork = config.getForkInfoAtEpoch(current_epoch);
        var current_proposer_seed: [32]u8 = undefined;
        try getSeed(state, current_epoch, params.DOMAIN_BEACON_PROPOSER, &current_proposer_seed);
        const proposers = std.ArrayList(u32).init(allocator);
        if (current_shuffling.active_indices.len > 0) {
            try proposers.resize(preset.SLOTS_PER_EPOCH);
            try computeProposers(allocator, fork, current_proposer_seed, current_epoch, current_shuffling.active_indices, effective_balance_increment, proposers.items);
        }

        // Only after altair, compute the indices of the current sync committee
        const after_altair_fork = current_epoch >= config.config.ALTAIR_FORK_EPOCH;

        // Values syncParticipantReward, syncProposerReward, baseRewardPerIncrement are only used after altair.
        // However, since they are very cheap to compute they are computed always to simplify upgradeState function.
        const sync_participant_reward = computeSyncParticipantReward(total_active_balance_increments);
        const sync_proposer_reward = @divFloor(sync_participant_reward, PROPOSER_WEIGHT_FACTOR);
        const base_reward_pre_increment = computeBaseRewardPerIncrement(total_active_balance_increments);
        const skip_sync_committee_cache = if (option) |opt| opt.skip_sync_committee_cache else !after_altair_fork;
        const current_sync_committee_indexed = if (skip_sync_committee_cache) SyncCommitteeCacheAllForks.initEmpty() else try SyncCommitteeCacheAllForks.computeSyncCommitteeCache(allocator, state.getCurrentSyncCommittee(), pubkey_to_index);
        const next_sync_committee_indexed = if (skip_sync_committee_cache) SyncCommitteeCacheAllForks.initEmpty() else try SyncCommitteeCacheAllForks.computeSyncCommitteeCache(allocator, state.getNextSyncCommittee(), pubkey_to_index);

        // Precompute churnLimit for efficient initiateValidatorExit() during block proposing MUST be recompute everytime the
        // active validator indices set changes in size. Validators change active status only when:
        // - validator.activation_epoch is set. Only changes in process_registry_updates() if validator can be activated. If
        //   the value changes it will be set to `epoch + 1 + MAX_SEED_LOOKAHEAD`.
        // - validator.exit_epoch is set. Only changes in initiate_validator_exit() if validator exits. If the value changes,
        //   it will be set to at least `epoch + 1 + MAX_SEED_LOOKAHEAD`.
        // ```
        // is_active_validator = validator.activation_epoch <= epoch < validator.exit_epoch
        // ```
        // So the returned value of is_active_validator(epoch) is guaranteed to not change during `MAX_SEED_LOOKAHEAD` epochs.
        //
        // activeIndices size is dependent on the state epoch. The epoch is advanced after running the epoch transition, and
        // the first block of the epoch process_block() call. So churnLimit must be computed at the end of the before epoch
        // transition and the result is valid until the end of the next epoch transition
        const churn_limit = getChurnLimit(config, current_shuffling.active_indices.len);
        const fork_seq = config.getForkSeq(state.getSlot());
        const activation_churn_limit = getActivationChurnLimit(config, fork_seq, current_shuffling.active_indices.len);
        if (exit_queue_churn >= churn_limit) {
            exit_queue_epoch += 1;
            exit_queue_churn = 0;
        }

        // TODO: describe issue. Compute progressive target balances
        // Compute balances from zero, note this state could be mid-epoch so target balances != 0
        var previous_target_unslashed_balance_increments = 0;
        var current_target_unslashed_balance_increments = 0;

        if (fork_seq >= ForkSeq.altair) {
            const previous_epoch_participation = state.getPreviousEpochParticipations();
            const current_epoch_participation = state.getCurrentEpochParticipations();

            previous_target_unslashed_balance_increments = sumTargetUnslashedBalanceIncrements(previous_epoch_participation, previous_epoch, validators);
            current_target_unslashed_balance_increments = sumTargetUnslashedBalanceIncrements(current_epoch_participation, current_epoch, validators);
        }

        return .{
            .allocator = allocator,
            .config = config,
            .pubkey_to_index = pubkey_to_index,
            .index_to_pubkey = index_to_pubkey,
            .proposers = proposers.items,
            // On first epoch, set to null to prevent unnecessary work since this is only used for metrics
            .proposer_prev_epoch = null,
            .previous_shuffling = EpochShufflingRc.init(previous_shuffling),
            .current_shuffling = EpochShufflingRc.init(current_shuffling),
            .next_shuffling = EpochShufflingRc.init(next_shuffling),
            .effective_balance_increment = EffectiveBalanceIncrementsRc.init(effective_balance_increment),
            .total_slashings_by_increment = total_slashings_by_increment,
            .sync_participant_reward = sync_participant_reward,
            .sync_proposer_reward = sync_proposer_reward,
            .base_reward_per_increment = base_reward_pre_increment,
            .total_acrive_balance_increments = total_active_balance_increments,
            .churn_limit = churn_limit,
            .activation_churn_limit = activation_churn_limit,
            .exit_queue_epoch = exit_queue_epoch,
            .exit_queue_churn = exit_queue_churn,
            .current_target_unslashed_balance_increments = current_target_unslashed_balance_increments,
            .previous_target_unslashed_balance_increments = previous_target_unslashed_balance_increments,
            .current_sync_committee_indexed = SyncCommitteeCacheRc.init(current_sync_committee_indexed),
            .next_sync_committee_indexed = SyncCommitteeCacheRc.init(next_sync_committee_indexed),
            .sync_period = computeSyncPeriodAtEpoch(current_epoch),
            .epoch = current_epoch,
            .next_epoch = next_epoch,
        };
    }

    pub fn deinit(self: *EpochCache) void {
        // pubkey_to_index and index_to_pubkey are shared across applications, EpochCache does not own this field so should not deinit()

        // unref the epoch shufflings
        self.previous_shuffling.release();
        self.current_shuffling.release();
        self.next_shuffling.release();

        // unref the effective balance increments
        self.effective_balance_increment.release();

        // unref the sync committee caches
        self.current_sync_committee_indexed.release();
        self.next_sync_committee_indexed.release();
    }

    pub fn clone(self: *const EpochCache) EpochCache {
        return .EpochCache{
            .allocator = self.allocator,
            .config = self.config,
            // Common append-only structures shared with all states, no need to clone
            .pubkey_to_index = self.pubkey_to_index,
            .index_to_pubkey = self.index_to_pubkey,
            // Immutable data
            .proposers = self.proposers,
            .proposer_prev_epoch = self.proposer_prev_epoch,
            // reuse the same instances, increase reference count
            .previous_shuffling = self.previous_shuffling.acquire(),
            .current_shuffling = self.current_shuffling.acquire(),
            .next_shuffling = self.next_shuffling.acquire(),
            // reuse the same instances, increase reference count, cloned only when necessary before an epoch transition
            .effective_balance_increment = self.effective_balance_increment.acquire(),
            .total_slashings_by_increment = self.total_slashings_by_increment,
            // Basic types (numbers) cloned implicitly
            .sync_participant_reward = self.sync_participant_reward,
            .sync_proposer_reward = self.sync_proposer_reward,
            .base_reward_per_increment = self.base_reward_per_increment,
            .total_acrive_balance_increments = self.total_acrive_balance_increments,
            .churn_limit = self.churn_limit,
            .activation_churn_limit = self.activation_churn_limit,
            .exit_queue_epoch = self.exit_queue_epoch,
            .exit_queue_churn = self.exit_queue_churn,
            .current_target_unslashed_balance_increments = self.current_target_unslashed_balance_increments,
            .previous_target_unslashed_balance_increments = self.previous_target_unslashed_balance_increments,
            // reuse the same instances, increase reference count
            .current_sync_committee_indexed = self.current_sync_committee_indexed.acquire(),
            .next_sync_committee_indexed = self.next_sync_committee_indexed.acquire(),
            .sync_period = self.sync_period,
            .epoch = self.epoch,
            .next_epoch = self.next_epoch,
        };
    }

    // TODO: afterProcessEpoch

    pub fn beforeEpochTransition(self: *EpochCache) void {
        // Clone (copy) before being mutated in processEffectiveBalanceUpdates
        const effective_balance_increment = EffectiveBalanceIncrements.initCapacity(self.allocator, self.effective_balance_increment.items.len);
        effective_balance_increment.appendSlice(self.effective_balance_increment.items);
        // unref the previous effective balance increment
        self.effective_balance_increment.release();
        self.effective_balance_increment = EffectiveBalanceIncrementsRc.init(effective_balance_increment);
    }

    pub fn getBeaconCommittee(self: *const EpochCache, slot: Slot, index: CommitteeIndex) ![]const u32 {
        const epoch_committees = self.getShufflingAtSlotOrNull(slot) orelse error.EpochShufflingNotFound;
        const slot_committees = epoch_committees[slot % preset.SLOTS_PER_EPOCH];
        if (index >= slot_committees.len) {
            return error.CommitteeIndexOutOfBounds;
        }
        return slot_committees[index];
    }

    // TODO: getBeaconCommittees: may not needed

    pub fn getCommitteeCountPerSlot(self: *const EpochCache, epoch: Epoch) !usize {
        const shuffling = self.getShufflingAtEpochOrNull(epoch) orelse error.EpochShufflingNotFound;
        return shuffling.committees_per_slot;
    }

    pub fn computeSubnetForSlot(self: *const EpochCache, slot: Slot, committee_index: CommitteeIndex) !u8 {
        const slots_since_epoch_start = slot % preset.SLOTS_PER_EPOCH;
        const committees_per_slot = try self.getCommitteeCountPerSlot(computeEpochAtSlot(slot));
        const committees_since_epoch_start = committees_per_slot * slots_since_epoch_start;
        return @intCast((committees_since_epoch_start + committee_index) % params.ATTESTATION_SUBNET_COUNT);
    }

    pub fn getBeaconProposer(self: *const EpochCache, slot: Slot) !ValidatorIndex {
        const epoch = computeEpochAtSlot(slot);
        if (epoch != self.epoch) return error.NotCurrentEpoch;

        return self.proposers[slot % preset.SLOTS_PER_EPOCH];
    }

    // TODO: getBeaconProposers - can access directly?

    // TODO: getBeaconProposersNextEpoch - may not needed post-fulu

    // TODO: is getBeaconCommittees necessary?

    // TODO: getIndexedAttestation - need getAttestingIndices

    // TODO: getAttestingIndices - need ssz getTrueBitIndexes

    // TODO: getCommitteeAssignments

    // TODO: getCommitteeAssignment

    pub fn isAggregator(self: *const EpochCache, slot: Slot, index: CommitteeIndex, slot_signature: BLSSignature) !bool {
        const committee = try self.getBeaconCommittee(slot, index);
        return isAggregatorFromCommitteeLength(committee.length, slot_signature);
    }

    pub fn getPubkey(self: *const EpochCache, index: ValidatorIndex) ?Publickey {
        return if (index < self.index_to_pubkey.items.len) self.index_to_pubkey[index] else null;
    }

    pub fn getValidatorIndex(self: *const EpochCache, pubkey: BLSPubkey) ?ValidatorIndex {
        return self.pubkey_to_index.get(pubkey[0..]);
    }

    pub fn addPubkey(self: *EpochCache, index: ValidatorIndex, pubkey: Publickey) !void {
        self.pubkey_to_index.set(pubkey[0..], index);
        self.index_to_pubkey.set(index, try BLSPubkey.fromBytes(pubkey));
    }

    // TODO: getBeaconCommittee
    pub fn getShufflingAtSlotOrNull(self: *const EpochCache, slot: Slot) ?EpochShuffling {
        const epoch = computeEpochAtSlot(slot);
        return self.getShufflingAtEpochOrNull(epoch);
    }

    pub fn getShufflingAtEpochOrNull(self: *const EpochCache, epoch: Epoch) ?EpochShuffling {
        switch (epoch) {
            self.epoch - 1 => return self.previous_shuffling.get(),
            self.epoch => return self.current_shuffling.get(),
            self.next_epoch => return self.next_shuffling.get(),
            else => return null,
        }
    }

    /// Note: The range of slots a validator has to perform duties is off by one.
    /// The previous slot wording means that if your validator is in a sync committee for a period that runs from slot
    /// 100 to 200,then you would actually produce signatures in slot 99 - 199.
    pub fn getIndexedSyncCommittee(self: *const EpochCache, slot: Slot) !SyncCommitteeCacheAllForks {
        // See note above for the +1 offset
        return self.getIndexedSyncCommitteeAtEpoch(computeEpochAtSlot(slot + 1));
    }

    pub fn getIndexedSyncCommitteeAtEpoch(self: *const EpochCache, epoch: Epoch) !SyncCommitteeCacheAllForks {
        const sync_period = computeSyncPeriodAtEpoch(epoch);
        switch (sync_period) {
            self.sync_period => return self.current_sync_committee_indexed.get(),
            self.sync_period + 1 => return self.next_sync_committee_indexed.get(),
            else => return error.SyncCommitteeNotFound,
        }
    }

    pub fn rotateSyncCommitteeIndexed(self: *EpochCache, next_sync_committee_indices: ValidatorIndices) !void {
        // unref the old instance
        self.current_sync_committee_indexed.release();
        // this is the transfer of reference count
        // should not do an release() then acquire() here as it may trigger a deinit()
        self.current_sync_committee_indexed = self.next_sync_committee_indexed;
        self.next_sync_committee_indexed = SyncCommitteeCacheRc.acquire(try SyncCommitteeCacheAllForks.getSyncCommitteeCache(self.allocator, next_sync_committee_indices));
    }

    // TODO: review the use of this function, use the rotateSyncCommitteeIndexed() instead
    // TODO: also increase reference count
    // pub fn setSyncCommitteesIndexed(self: *EpochCache, next_sync_committee_indices: ValidatorIndices) !void {
    //     self.next_sync_committee_indexed = try SyncCommitteeCacheAllForks.getSyncCommitteeCache(self.allocator, next_sync_committee_indices);
    //     self.current_sync_committee_indexed = self.next_sync_committee_indexed;
    // }

    /// This is different from typescript version: only allocate new EffectiveBalanceIncrements if needed
    pub fn effectiveBalanceIncrementsSet(self: *const EpochCache, index: usize, effective_balance: u64) void {
        var effective_balance_increments = self.effective_balance_increment.get();
        if (index >= effective_balance_increments.items.len) {
            // Clone and extend effectiveBalanceIncrements
            effective_balance_increments = getEffectiveBalanceIncrementsWithLen(self.allocator, index + 1);
            self.effective_balance_increment.release();
            self.effective_balance_increment = EffectiveBalanceIncrementsRc.init(effective_balance_increments);
        }
        self.effective_balance_increment.get().items[index] = @divFloor(effective_balance, preset.EFFECTIVE_BALANCE_INCREMENT);
    }

    pub fn isPostElectra(self: *const EpochCache) bool {
        return self.epoch >= self.config.config.ELECTRA_FORK_EPOCH;
    }
};
