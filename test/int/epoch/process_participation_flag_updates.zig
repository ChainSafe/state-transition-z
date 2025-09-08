const std = @import("std");
const Allocator = std.mem.Allocator;
const state_transition = @import("state_transition");
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const ReusedEpochTransitionCache = state_transition.ReusedEpochTransitionCache;
const EpochTransitionCache = state_transition.EpochTransitionCache;
const processParticipationFlagUpdates = state_transition.processParticipationFlagUpdates;
// this function runs without EpochTransionCache so cannot use getTestProcessFn

test "processParticipationFlagUpdates - sanity" {
    const allocator = std.testing.allocator;
    const validator_count_arr = &.{ 256, 10_000 };

    var reused_epoch_transition_cache = try ReusedEpochTransitionCache.init(allocator, validator_count_arr[0]);
    defer reused_epoch_transition_cache.deinit();

    inline for (validator_count_arr) |validator_count| {
        var test_state = try TestCachedBeaconStateAllForks.init(allocator, validator_count);
        defer test_state.deinit();

        var epoch_transition_cache: EpochTransitionCache = undefined;
        try EpochTransitionCache.beforeProcessEpoch(
            allocator,
            test_state.cached_state,
            &reused_epoch_transition_cache,
            &epoch_transition_cache,
        );
        defer epoch_transition_cache.deinit();

        try processParticipationFlagUpdates(test_state.cached_state, allocator);
    }
}
