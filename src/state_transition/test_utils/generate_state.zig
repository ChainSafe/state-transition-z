const std = @import("std");
const blst = @import("blst");
const Allocator = std.mem.Allocator;
const mainnet_chain_config = @import("config").mainnet_chain_config;
const ssz = @import("consensus_types");
const ElectraBeaconState = ssz.electra.BeaconState.Type;
const BLSPubkey = ssz.primitive.BLSPubkey.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const preset = @import("preset").preset;
const BeaconConfig = @import("config").BeaconConfig;
const ChainConfig = @import("config").ChainConfig;
const state_transition = @import("../root.zig");
const CachedBeaconStateAllForks = state_transition.CachedBeaconStateAllForks;
const BeaconStateAllForks = state_transition.BeaconStateAllForks;
const PubkeyIndexMap = state_transition.PubkeyIndexMap(ValidatorIndex);
const Index2PubkeyCache = state_transition.Index2PubkeyCache;
const EffectiveBalanceIncrements = state_transition.EffectiveBalanceIncrements;
const getNextSyncCommitteeIndices = state_transition.getNextSyncCommitteeIndices;
const syncPubkeys = state_transition.syncPubkeys;
const interopPubkeysCached = @import("./interop_pubkeys.zig").interopPubkeysCached;
const EFFECTIVE_BALANCE_INCREMENT = 32;
const EFFECTIVE_BALANCE = 32 * 1e9;

/// generate, allocate BeaconStateAllForks
/// consumer has responsibility to deinit it
pub fn generateElectraState(allocator: Allocator, chain_config: ChainConfig, validator_count: usize) !*BeaconStateAllForks {
    const electra_state = try allocator.create(ElectraBeaconState);
    electra_state.* = ssz.electra.BeaconState.default_value;
    // set the slot to be ready for the next epoch transition
    electra_state.slot = chain_config.ELECTRA_FORK_EPOCH * preset.SLOTS_PER_EPOCH + 2025 * preset.SLOTS_PER_EPOCH - 1;

    const pubkeys = try allocator.alloc(BLSPubkey, validator_count);
    defer allocator.free(pubkeys);
    try interopPubkeysCached(validator_count, pubkeys);

    for (0..validator_count) |i| {
        const validator = ssz.phase0.Validator.Type{
            .pubkey = pubkeys[i],
            .withdrawal_credentials = [_]u8{0} ** 32,
            .effective_balance = EFFECTIVE_BALANCE,
            .slashed = false,
            .activation_eligibility_epoch = 0,
            .activation_epoch = 0,
            .exit_epoch = 0xFFFFFFFFFFFFFFFF,
            .withdrawable_epoch = 0xFFFFFFFFFFFFFFFF,
        };
        try electra_state.validators.append(allocator, validator);
        try electra_state.balances.append(allocator, EFFECTIVE_BALANCE);
        try electra_state.inactivity_scores.append(allocator, 0);
        try electra_state.previous_epoch_participation.append(allocator, 0b11111111);
        try electra_state.current_epoch_participation.append(allocator, 0b11111111);
    }

    var active_validator_indices = try std.ArrayList(ValidatorIndex).initCapacity(allocator, validator_count);
    defer active_validator_indices.deinit();
    var effective_balance_increments = try EffectiveBalanceIncrements.initCapacity(allocator, validator_count);
    defer effective_balance_increments.deinit();
    for (0..validator_count) |i| {
        try active_validator_indices.append(@intCast(i));
        try effective_balance_increments.append(EFFECTIVE_BALANCE_INCREMENT);
    }

    // the same logic to processSyncCommitteeUpdates
    const beacon_state = try allocator.create(BeaconStateAllForks);
    beacon_state.* = .{ .electra = electra_state };
    const validators = beacon_state.validators();
    var next_sync_committee_indices: [preset.SYNC_COMMITTEE_SIZE]ValidatorIndex = undefined;
    try getNextSyncCommitteeIndices(allocator, beacon_state, active_validator_indices.items, &effective_balance_increments, &next_sync_committee_indices);

    var next_sync_committee_pubkeys: [preset.SYNC_COMMITTEE_SIZE]BLSPubkey = undefined;
    var next_sync_committee_pubkeys_slices: [preset.SYNC_COMMITTEE_SIZE]blst.PublicKey = undefined;
    for (next_sync_committee_indices, 0..next_sync_committee_indices.len) |index, i| {
        next_sync_committee_pubkeys[i] = validators.items[index].pubkey;
        next_sync_committee_pubkeys_slices[i] = try blst.PublicKey.uncompress(&next_sync_committee_pubkeys[i]);
    }

    const current_sync_committee = beacon_state.currentSyncCommittee();
    const next_sync_committee = beacon_state.nextSyncCommittee();
    // Rotate syncCommittee in state
    next_sync_committee.* = .{
        .pubkeys = next_sync_committee_pubkeys,
        .aggregate_pubkey = (try blst.AggregatePublicKey.aggregate(&next_sync_committee_pubkeys_slices, false)).toPublicKey().compress(),
    };

    // initialize current sync committee to be the same as next sync committee
    current_sync_committee.* = next_sync_committee.*;

    return beacon_state;
}

pub const TestCachedBeaconStateAllForks = struct {
    allocator: Allocator,
    config: *BeaconConfig,
    pubkey_index_map: *PubkeyIndexMap,
    index_pubkey_cache: *Index2PubkeyCache,
    cached_state: *CachedBeaconStateAllForks,

    pub fn init(allocator: Allocator, validator_count: usize) !TestCachedBeaconStateAllForks {
        const pubkey_index_map = try PubkeyIndexMap.init(allocator);
        const index_pubkey_cache = try allocator.create(Index2PubkeyCache);
        index_pubkey_cache.* = Index2PubkeyCache.init(allocator);
        const state = try generateElectraState(allocator, mainnet_chain_config, validator_count);
        const config = try BeaconConfig.init(allocator, mainnet_chain_config, state.genesisValidatorsRoot());

        try syncPubkeys(state.validators().items, pubkey_index_map, index_pubkey_cache);

        const immutable_data = state_transition.EpochCacheImmutableData{
            .config = config,
            .index_to_pubkey = index_pubkey_cache,
            .pubkey_to_index = pubkey_index_map,
        };
        const cached_state = try CachedBeaconStateAllForks.createCachedBeaconState(allocator, state, immutable_data, .{
            .skip_sync_committee_cache = false,
            .skip_sync_pubkeys = false,
        });

        return TestCachedBeaconStateAllForks{
            .allocator = allocator,
            .config = config,
            .pubkey_index_map = pubkey_index_map,
            .index_pubkey_cache = index_pubkey_cache,
            .cached_state = cached_state,
        };
    }

    pub fn deinit(self: *TestCachedBeaconStateAllForks) void {
        self.config.deinit();
        self.pubkey_index_map.deinit();
        self.index_pubkey_cache.deinit();
        self.allocator.destroy(self.index_pubkey_cache);
        self.cached_state.deinit(self.allocator);
        self.allocator.destroy(self.cached_state);
    }
};

test TestCachedBeaconStateAllForks {
    const allocator = std.testing.allocator;
    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();
}
