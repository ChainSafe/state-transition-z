const std = @import("std");
const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;
const state_transition = @import("state_transition");
const ReusedEpochTransitionCache = state_transition.ReusedEpochTransitionCache;
const EpochTransitionCache = state_transition.EpochTransitionCache;

test "EpochTransitionCache.initBeforeProcessEpoch" {
    const allocator = std.testing.allocator;
    const validator_count_arr = &.{ 256, 10_000 };
    inline for (validator_count_arr) |validator_count| {
        var test_state = try TestCachedBeaconStateAllForks.init(allocator, validator_count);
        defer test_state.deinit();

        var reused_epoch_transition_cache = try ReusedEpochTransitionCache.init(allocator, validator_count);
        defer reused_epoch_transition_cache.deinit();

        var epoch_transition_cache = try EpochTransitionCache.initBeforeProcessEpoch(
            allocator,
            test_state.cached_state,
            &reused_epoch_transition_cache,
        );
        defer epoch_transition_cache.deinit();
    }
}
