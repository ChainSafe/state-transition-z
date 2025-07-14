const std = @import("std");
const Allocator = std.mem.Allocator;
const BeaconConfig = @import("config").BeaconConfig;
const EpochCacheRc = @import("./epoch_cache.zig").EpochCacheRc;
const EpochCache = @import("./epoch_cache.zig").EpochCache;
const EpochCacheImmutableData = @import("./epoch_cache.zig").EpochCacheImmutableData;
const EpochCacheOpts = @import("./epoch_cache.zig").EpochCacheOpts;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;

// TODO: create a generic struct with state type if needed
pub const CachedBeaconStateAllForks = struct {
    allocator: Allocator,
    /// only a reference to the singleton BeaconConfig
    config: *const BeaconConfig,
    /// only a reference to the shared EpochCache instance
    /// TODO: before an epoch transition, need to release() epoch_cache before using a new one
    epoch_cache: EpochCacheRc,
    /// this takes ownership of the state, it is expected to be deinitialized by this struct
    state: *BeaconStateAllForks,

    // TODO: cloned_count properties, implement this once we switch to TreeView
    // TODO: proposer_rewards, looks like this is not a great place to put in, it's a result of a block state transition instead

    /// This class takes ownership of state after this function and has responsibility to deinit it
    pub fn createCachedBeaconState(allocator: Allocator, state: *BeaconStateAllForks, immutable_data: EpochCacheImmutableData, option: ?EpochCacheOpts) !*CachedBeaconStateAllForks {
        const epoch_cache = try EpochCache.createFromState(allocator, state, immutable_data, option);
        const epoch_cache_ref = EpochCacheRc.init(epoch_cache);
        const cached_state = try allocator.create(CachedBeaconStateAllForks);
        cached_state.* = .{
            .allocator = allocator,
            .config = immutable_data.config,
            .epoch_cache = epoch_cache_ref,
            .state = state,
        };
        cached_state;
    }

    pub fn getEpochCache(self: *const CachedBeaconStateAllForks) *EpochCache {
        return self.epoch_cache.get();
    }

    pub fn deinit(allocator: Allocator, self: *CachedBeaconStateAllForks) void {
        // should not deinit config since we don't take ownership of it, it's singleton across applications
        self.epoch_cache.release();
        self.state.deinit(allocator);
        self.allocator.destroy(self.state);
    }

    // TODO: implement loadCachedBeaconState
    // this is used when we load a state from disc, given a seed state
    // need to do this once we switch to TreeView

    // TODO: implement getCachedBeaconState
    // this is used to create a CachedBeaconStateAllForks based on a tree and an exising CachedBeaconStateAllForks at fork transition
    // implement this once we switch to TreeView
};
