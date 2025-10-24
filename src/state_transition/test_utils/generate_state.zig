const std = @import("std");
const blst = @import("blst");
const Allocator = std.mem.Allocator;
const ForkSeq = @import("config").ForkSeq;
const mainnet_chain_config = @import("config").mainnet_chain_config;
const minimal_chain_config = @import("config").minimal_chain_config;
const ssz = @import("consensus_types");
const hex = @import("hex");
const ElectraBeaconState = ssz.electra.BeaconState.Type;
const BLSPubkey = ssz.primitive.BLSPubkey.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const Epoch = ssz.primitive.Epoch.Type;
const preset = @import("preset").preset;
const active_preset = @import("preset").active_preset;
const BeaconConfig = @import("config").BeaconConfig;
const ChainConfig = @import("config").ChainConfig;
const mergeChainConfig = @import("config").mergeChainConfig;
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
const active_chain_config = if (active_preset == .mainnet) mainnet_chain_config else minimal_chain_config;

/// generate, allocate BeaconStateAllForks
/// consumer has responsibility to deinit it
pub fn generateElectraState(allocator: Allocator, chain_config: ChainConfig, validator_count: usize) !*BeaconStateAllForks {
    const electra_state = try allocator.create(ElectraBeaconState);
    errdefer allocator.destroy(electra_state);
    electra_state.* = ssz.electra.BeaconState.default_value;
    electra_state.genesis_time = 1596546008;
    electra_state.genesis_validators_root = try hex.hexToRoot("0x8a8b3f1f1e2d3c4b5a697887766554433221100ffeeddccbbaa9988776655443");
    // set the slot to be ready for the next epoch transition
    electra_state.slot = chain_config.ELECTRA_FORK_EPOCH * preset.SLOTS_PER_EPOCH + 2025 * preset.SLOTS_PER_EPOCH - 1;
    const current_epoch = @divFloor(electra_state.slot, preset.SLOTS_PER_EPOCH);
    var version: [4]u8 = undefined;
    _ = try hex.hexToBytes(&version, "0x00000001");
    electra_state.fork = .{
        .previous_version = version,
        .current_version = version,
        .epoch = chain_config.ELECTRA_FORK_EPOCH,
    };
    electra_state.latest_block_header = .{
        .slot = electra_state.slot - 1,
        .proposer_index = 80882,
        .parent_root = try hex.hexToRoot("0x5b83c3078e474b86af60043eda82a34c3c2e5ebf83146b14d9d909aea4163ef2"),
        .state_root = try hex.hexToRoot("0x2761ae355e8a53c11e0e37d5e417f8984db0c53fa83f1bc65f89c6af35a196a7"),
        .body_root = try hex.hexToRoot("0x249a1962eef90e122fa2447040bfac102798b1dba9c73e5593bc5aa32eb92bfd"),
    };
    electra_state.block_roots = [_][32]u8{[_]u8{1} ** 32} ** preset.SLOTS_PER_HISTORICAL_ROOT;
    electra_state.state_roots = [_][32]u8{[_]u8{2} ** 32} ** preset.SLOTS_PER_HISTORICAL_ROOT;

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

    electra_state.eth1_data = .{
        .deposit_root = try hex.hexToRoot("0xcb1f89a924cfd31224823db5a41b1643f10faa7aedf231f1e28887f6ee98c047"),
        .deposit_count = pubkeys.len,
        .block_hash = try hex.hexToRoot("0x701fb2869ce16d0f1d14f6705725adb0dec6799da29006dfc6fff83960298f21"),
    };

    // populate sync committee
    var active_validator_indices = try std.ArrayList(ValidatorIndex).initCapacity(allocator, validator_count);
    defer active_validator_indices.deinit();
    var effective_balance_increments = try EffectiveBalanceIncrements.initCapacity(allocator, validator_count);
    defer effective_balance_increments.deinit();
    for (0..validator_count) |i| {
        try active_validator_indices.append(@intCast(i));
        try effective_balance_increments.append(EFFECTIVE_BALANCE_INCREMENT);
    }

    // no need to populate eth1_data_votes
    electra_state.eth1_deposit_index = pubkeys.len;
    // enable this will cause some tests failed
    // electra_state.randao_mixes = [_][32]u8{[_]u8{4} ** 32} ** preset.EPOCHS_PER_HISTORICAL_VECTOR;
    // no need to populate slashings
    // finality
    electra_state.justification_bits = ssz.phase0.JustificationBits.default_value;
    for (0..4) |i| {
        try electra_state.justification_bits.set(i, true);
    }
    electra_state.previous_justified_checkpoint = .{
        .epoch = current_epoch - 2,
        .root = try hex.hexToRoot("0x3fe60bf06a57b0956cd1f8181d26649cf8bf79e48bf82f55562e04b33d4785d4"),
    };
    electra_state.current_justified_checkpoint = .{
        .epoch = current_epoch - 1,
        .root = try hex.hexToRoot("0x3ba0913d2fb5e4cbcfb0d39eb15803157c1e769d63b8619285d8fdabbd8181c7"),
    };
    electra_state.finalized_checkpoint = .{
        .epoch = current_epoch - 3,
        .root = try hex.hexToRoot("0x122b8ff579d0c8f8a8b66326bdfec3f685007d2842f01615a0768870961ccc17"),
    };

    // the same logic to processSyncCommitteeUpdates
    const beacon_state = try allocator.create(BeaconStateAllForks);
    errdefer allocator.destroy(beacon_state);
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
        const state = try generateElectraState(allocator, active_chain_config, validator_count);
        errdefer state.deinit(allocator);
        defer allocator.destroy(state);

        return initFromState(allocator, state, ForkSeq.electra, state.fork().epoch);
    }

    pub fn initFromState(allocator: Allocator, state: *BeaconStateAllForks, fork: ForkSeq, fork_epoch: Epoch) !TestCachedBeaconStateAllForks {
        const owned_state = try allocator.create(BeaconStateAllForks);
        owned_state.* = state.*;

        const pubkey_index_map = try PubkeyIndexMap.init(allocator);
        const index_pubkey_cache = try allocator.create(Index2PubkeyCache);
        errdefer allocator.destroy(index_pubkey_cache);
        index_pubkey_cache.* = Index2PubkeyCache.init(allocator);
        const chain_config = getConfig(active_chain_config, fork, fork_epoch);
        const config = try BeaconConfig.init(allocator, chain_config, owned_state.genesisValidatorsRoot());

        try syncPubkeys(owned_state.validators().items, pubkey_index_map, index_pubkey_cache);

        const immutable_data = state_transition.EpochCacheImmutableData{
            .config = config,
            .index_to_pubkey = index_pubkey_cache,
            .pubkey_to_index = pubkey_index_map,
        };
        // cached_state takes ownership of state and will deinit there
        const cached_state = try CachedBeaconStateAllForks.createCachedBeaconState(allocator, owned_state, immutable_data, .{
            .skip_sync_committee_cache = owned_state.isPhase0(),
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
        self.cached_state.deinit();
        self.allocator.destroy(self.cached_state);
    }
};

/// get a ChainConfig for spec test, refer to https://github.com/ChainSafe/lodestar/blob/v1.35.0/packages/beacon-node/test/utils/config.ts#L9
pub fn getConfig(config: ChainConfig, fork: ForkSeq, fork_epoch: Epoch) ChainConfig {
    switch (fork) {
        .phase0 => return config,
        .altair => return mergeChainConfig(config, .{
            .ALTAIR_FORK_EPOCH = fork_epoch,
        }),
        .bellatrix => return mergeChainConfig(config, .{
            .ALTAIR_FORK_EPOCH = 0,
            .BELLATRIX_FORK_EPOCH = fork_epoch,
        }),
        .capella => return mergeChainConfig(config, .{
            .ALTAIR_FORK_EPOCH = 0,
            .BELLATRIX_FORK_EPOCH = 0,
            .CAPELLA_FORK_EPOCH = fork_epoch,
        }),
        .deneb => return mergeChainConfig(config, .{
            .ALTAIR_FORK_EPOCH = 0,
            .BELLATRIX_FORK_EPOCH = 0,
            .CAPELLA_FORK_EPOCH = 0,
            .DENEB_FORK_EPOCH = fork_epoch,
        }),
        .electra => return mergeChainConfig(config, .{
            .ALTAIR_FORK_EPOCH = 0,
            .BELLATRIX_FORK_EPOCH = 0,
            .CAPELLA_FORK_EPOCH = 0,
            .DENEB_FORK_EPOCH = 0,
            .ELECTRA_FORK_EPOCH = fork_epoch,
        }),
    }
}

test TestCachedBeaconStateAllForks {
    const allocator = std.testing.allocator;
    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();
}
