const std = @import("std");
const Allocator = std.mem.Allocator;
const TestCachedBeaconStateAllForks = @import("test_utils").TestCachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const Root = ssz.primitive.Root.Type;
const ZERO_HASH = @import("constants").ZERO_HASH;

const state_transition = @import("state_transition");
const stateTransition = state_transition.state_transition.stateTransition;
const SignedBeaconBlock = state_transition.state_transition.SignedBeaconBlock;
const CachedBeaconStateAllForks = state_transition.CachedBeaconStateAllForks;
const SignedBlock = state_transition.SignedBlock;

//test "stf" {
//    const allocator = std.testing.allocator;
//
//    var test_state = try TestCachedBeaconStateAllForks.init(allocator, 256);
//    defer test_state.deinit();
//    const block = &ssz.electra.SignedBeaconBlock.default_value;
//    const signed_beacon_block = SignedBeaconBlock{ .electra = block };
//    const signed_block = SignedBlock{ .regular = &signed_beacon_block };
//    _ = try stateTransition(allocator, test_state.cached_state, signed_block, .{});
//}
