const std = @import("std");
const Allocator = std.mem.Allocator;
const BeaconConfig = @import("../config.zig").BeaconConfig;
const EpochCache = @import("./epoch_cache.zig").EpochCache;
const EpochCacheImmutableData = @import("./epoch_cache.zig").EpochCacheImmutableData;
const EpochCacheOpts = @import("./epoch_cache.zig").EpochCacheOpts;
const BeaconStateAllForks = @import("../beacon_state.zig").BeaconStateAllForks;

// TODO: create a generic struct with state type if needed
pub const CachedBeaconStateAllForks = struct {
    config: *BeaconConfig,
    epoch_cache: *EpochCache,
    state: *BeaconStateAllForks,

    // TODO: cloned_count properties, implement this once we switch to TreeView
    // TODO: proposer_rewards, looks like this is not a great place to put in, it's a result of a block state transition instead

    pub fn createCachedBeaconState(allocator: Allocator, state: *BeaconStateAllForks, immutable_data: EpochCacheImmutableData, option: ?EpochCacheOpts) !*CachedBeaconStateAllForks {
        const epoch_cache = try EpochCache.createFromState(allocator, state, immutable_data, option);
        return &CachedBeaconStateAllForks{
            .config = immutable_data.config,
            .epoch_cache = epoch_cache,
            .state = state,
        };
    }

    // TODO: implement loadCachedBeaconState
    // this is used when we load a state from disc, given a seed state
    // need to do this once we switch to TreeView

    // TODO: implement getCachedBeaconState
    // this is used to create a CachedBeaconStateAllForks based on a tree and an exising CachedBeaconStateAllForks at fork transition
    // implement this once we switch to TreeView
};
