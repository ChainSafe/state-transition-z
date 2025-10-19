const std = @import("std");
const ssz = @import("consensus_types");
const Allocator = std.mem.Allocator;
const BeaconConfig = @import("config").BeaconConfig;
const EpochCacheRc = @import("./epoch_cache.zig").EpochCacheRc;
const EpochCache = @import("./epoch_cache.zig").EpochCache;
const EpochCacheImmutableData = @import("./epoch_cache.zig").EpochCacheImmutableData;
const EpochCacheOpts = @import("./epoch_cache.zig").EpochCacheOpts;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const PubkeyIndexMap = @import("pubkey_cache.zig").PubkeyIndexMap(ValidatorIndex);
const Index2PubkeyCache = @import("pubkey_cache.zig").Index2PubkeyCache;

pub const CachedBeaconStateAllForks = struct {
    allocator: Allocator,
    /// only a reference to the singleton BeaconConfig
    config: *const BeaconConfig,
    /// only a reference to the shared EpochCache instance
    /// TODO: before an epoch transition, need to release() epoch_cache before using a new one
    epoch_cache_ref: *EpochCacheRc,
    /// this takes ownership of the state, it is expected to be deinitialized by this struct
    state: *BeaconStateAllForks,

    // TODO: cloned_count properties, implement this once we switch to TreeView
    // TODO: proposer_rewards, looks like this is not a great place to put in, it's a result of a block state transition instead

    /// This class takes ownership of state after this function and has responsibility to deinit it
    pub fn createCachedBeaconState(allocator: Allocator, state: *BeaconStateAllForks, immutable_data: EpochCacheImmutableData, option: ?EpochCacheOpts) !*CachedBeaconStateAllForks {
        const epoch_cache = try EpochCache.createFromState(allocator, state, immutable_data, option);
        const epoch_cache_ref = try EpochCacheRc.init(allocator, epoch_cache);
        const cached_state = try allocator.create(CachedBeaconStateAllForks);
        cached_state.* = .{
            .allocator = allocator,
            .config = immutable_data.config,
            .epoch_cache_ref = epoch_cache_ref,
            .state = state,
        };
        return cached_state;
    }

    // TODO: do we need another getConst()?
    pub fn getEpochCache(self: *const CachedBeaconStateAllForks) *EpochCache {
        return self.epoch_cache_ref.get();
    }

    pub fn clone(self: *CachedBeaconStateAllForks, allocator: Allocator) !*CachedBeaconStateAllForks {
        const cloned = try self.state.clone(allocator);

        const ecr = self.epoch_cache_ref.get();
        const pubkey_index_map = try ecr.pubkey_to_index.clone();
        var index_pubkey_cache = try ecr.index_to_pubkey.clone();

        const immutable_data = EpochCacheImmutableData{
            .config = self.config,
            .index_to_pubkey = &index_pubkey_cache,
            .pubkey_to_index = pubkey_index_map,
        };

        const cached_state = CachedBeaconStateAllForks.createCachedBeaconState(
            self.allocator,
            cloned,
            immutable_data,
            .{
                .skip_sync_committee_cache = false,
                .skip_sync_pubkeys = false,
            },
        );
        return cached_state;
    }

    pub fn deinit(self: *CachedBeaconStateAllForks, allocator: Allocator) void {
        // should not deinit config since we don't take ownership of it, it's singleton across applications
        self.epoch_cache_ref.release();
        self.state.deinit(allocator);
        self.allocator.destroy(self.state);
    }

    // TODO: implement loadCachedBeaconState
    // this is used when we load a state from disc, given a seed state
    // need to do this once we switch to TreeView

    // TODO: implement getCachedBeaconState
    // this is used to create a CachedBeaconStateAllForks based on a tree and an exising CachedBeaconStateAllForks at fork transition
    // implement this once we switch to TreeView

    /// Get the beacon proposer index for a given slot
    /// For Fulu fork, uses proposer_lookahead from state
    /// For earlier forks, uses EpochCache.getBeaconProposer()
    pub fn getBeaconProposer(self: *const CachedBeaconStateAllForks, slot: ssz.primitive.Slot.Type) !ValidatorIndex {
        const preset_import = @import("preset").preset;
        const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;

        // For Fulu, use proposer_lookahead from state
        if (self.state.isFulu()) {
            const current_epoch = computeEpochAtSlot(self.state.slot());
            const slot_epoch = computeEpochAtSlot(slot);

            // proposer_lookahead covers current_epoch through current_epoch + MIN_SEED_LOOKAHEAD
            const lookahead_start_epoch = current_epoch;
            const lookahead_end_epoch = current_epoch + preset_import.MIN_SEED_LOOKAHEAD;

            if (slot_epoch < lookahead_start_epoch or slot_epoch > lookahead_end_epoch) {
                return error.SlotOutsideProposerLookahead;
            }

            const proposer_lookahead = self.state.proposerLookahead();
            const epoch_offset = slot_epoch - lookahead_start_epoch;
            const slot_in_epoch = slot % preset_import.SLOTS_PER_EPOCH;
            const index = epoch_offset * preset_import.SLOTS_PER_EPOCH + slot_in_epoch;

            return proposer_lookahead[index];
        }
        return self.getEpochCache().getBeaconProposer(slot);
    }
};
