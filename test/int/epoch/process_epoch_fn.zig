const std = @import("std");
const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;
const state_transition = @import("state_transition");
const ReusedEpochTransitionCache = state_transition.ReusedEpochTransitionCache;
const EpochTransitionCache = state_transition.EpochTransitionCache;

pub fn getTestProcessFn(process_epoch_fn: anytype, no_alloc: bool, no_err_return: bool, no_void_return: bool) type {
    return struct {
        pub fn testProcessEpochFn() !void {
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

                if (no_void_return) {
                    if (no_err_return) {
                        // no try
                        if (no_alloc) {
                            _ = process_epoch_fn(test_state.cached_state, &epoch_transition_cache);
                        } else {
                            _ = process_epoch_fn(allocator, test_state.cached_state, &epoch_transition_cache);
                        }
                    } else {
                        // with try
                        if (no_alloc) {
                            _ = try process_epoch_fn(test_state.cached_state, &epoch_transition_cache);
                        } else {
                            _ = try process_epoch_fn(allocator, test_state.cached_state, &epoch_transition_cache);
                        }
                    }
                } else {
                    if (no_err_return) {
                        // no try
                        if (no_alloc) {
                            process_epoch_fn(test_state.cached_state, &epoch_transition_cache);
                        } else {
                            process_epoch_fn(allocator, test_state.cached_state, &epoch_transition_cache);
                        }
                    } else {
                        // with try
                        if (no_alloc) {
                            try process_epoch_fn(test_state.cached_state, &epoch_transition_cache);
                        } else {
                            try process_epoch_fn(allocator, test_state.cached_state, &epoch_transition_cache);
                        }
                    }
                }
            }
        }
    };
}
