const std = @import("std");
const Allocator = std.mem.Allocator;
const state_transition = @import("state_transition");
const CachedBeaconStateAllForks = state_transition.CachedBeaconStateAllForks;

pub fn generateElectraState(allocator: Allocator) *CachedBeaconStateAllForks {}
