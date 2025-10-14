const std = @import("std");
const Allocator = std.mem.Allocator;
const mainnet_chain_config = @import("config").mainnet_chain_config;
const minimal_chain_config = @import("config").minimal_chain_config;
const ssz = @import("consensus_types");
const ElectraBeaconState = ssz.electra.BeaconState.Type;
const BLSPubkey = ssz.primitive.BLSPubkey.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const preset = @import("preset").preset;
const Preset = @import("preset").Preset;
const BeaconConfig = @import("config").BeaconConfig;
const ChainConfig = @import("config").ChainConfig;
const state_transition = @import("../root.zig");
const CachedBeaconStateAllForks = state_transition.CachedBeaconStateAllForks;
const BeaconStateAllForks = state_transition.BeaconStateAllForks;
const PubkeyIndexMap = state_transition.PubkeyIndexMap(ValidatorIndex);
const Index2PubkeyCache = state_transition.Index2PubkeyCache;
const syncPubkeys = state_transition.syncPubkeys;
const interopPubkeysCached = @import("./interop_pubkeys.zig").interopPubkeysCached;

/// generate, allocate BeaconStateAllForks
/// consumer has responsibility to deinit it
/// TODO: may move to test folder so that perf test can use this too
pub fn generateElectraState(allocator: Allocator, chain_config: ChainConfig, validator_count: usize) !*BeaconStateAllForks {
    const beacon_state_ptr = try allocator.create(ElectraBeaconState);
    beacon_state_ptr.* = ssz.electra.BeaconState.default_value;
    // set the slot to be ready for the next epoch transition
    beacon_state_ptr.slot = chain_config.ELECTRA_FORK_EPOCH * preset.SLOTS_PER_EPOCH + 2025 * preset.SLOTS_PER_EPOCH - 1;

    const pubkeys = try allocator.alloc(BLSPubkey, validator_count);
    defer allocator.free(pubkeys);
    try interopPubkeysCached(validator_count, pubkeys);

    for (0..validator_count) |i| {
        const validator = ssz.phase0.Validator.Type{
            .pubkey = pubkeys[i],
            .withdrawal_credentials = [_]u8{0} ** 32,
            .effective_balance = 32e9,
            .slashed = false,
            .activation_eligibility_epoch = 0,
            .activation_epoch = 0,
            .exit_epoch = 0xFFFFFFFFFFFFFFFF,
            .withdrawable_epoch = 0xFFFFFFFFFFFFFFFF,
        };
        try beacon_state_ptr.validators.append(allocator, validator);
        try beacon_state_ptr.balances.append(allocator, 32e9);
        try beacon_state_ptr.inactivity_scores.append(allocator, 0);
        try beacon_state_ptr.previous_epoch_participation.append(allocator, 0b11111111);
        try beacon_state_ptr.current_epoch_participation.append(allocator, 0b11111111);
    }
    for (0..preset.SYNC_COMMITTEE_SIZE) |i| {
        const pubkey = pubkeys[i % validator_count];
        beacon_state_ptr.current_sync_committee.pubkeys[i] = pubkey;
        beacon_state_ptr.next_sync_committee.pubkeys[i] = pubkey;
    }
    const cached_beacon_state_ptr = try allocator.create(BeaconStateAllForks);
    cached_beacon_state_ptr.* = .{ .electra = beacon_state_ptr };
    return cached_beacon_state_ptr;
}

pub const TestCachedBeaconStateAllForks = struct {
    allocator: Allocator,
    config: *BeaconConfig,
    pubkey_index_map: *PubkeyIndexMap,
    index_pubkey_cache: *Index2PubkeyCache,
    cached_state: *CachedBeaconStateAllForks,

    pub fn init(allocator: Allocator, validator_count: usize) !TestCachedBeaconStateAllForks {
        const state = try generateElectraState(allocator, if (preset.preset == Preset.mainnet) mainnet_chain_config else minimal_chain_config, validator_count);
        return initFromState(allocator, state);
    }

    pub fn initFromState(allocator: Allocator, state: *BeaconStateAllForks) !TestCachedBeaconStateAllForks {
        const owned_state = try allocator.create(BeaconStateAllForks);
        owned_state.* = state.*;

        const pubkey_index_map = try PubkeyIndexMap.init(allocator);
        const index_pubkey_cache = try allocator.create(Index2PubkeyCache);
        index_pubkey_cache.* = Index2PubkeyCache.init(allocator);
        const config = try BeaconConfig.init(allocator, if (preset.preset == Preset.mainnet) mainnet_chain_config else minimal_chain_config, owned_state.genesisValidatorsRoot());

        try syncPubkeys(owned_state.validators().items, pubkey_index_map, index_pubkey_cache);

        const immutable_data = state_transition.EpochCacheImmutableData{
            .config = config,
            .index_to_pubkey = index_pubkey_cache,
            .pubkey_to_index = pubkey_index_map,
        };
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
        self.cached_state.deinit(self.allocator);
        self.allocator.destroy(self.cached_state);
    }
};

test TestCachedBeaconStateAllForks {
    const allocator = std.testing.allocator;
    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
    defer test_state.deinit();
}
