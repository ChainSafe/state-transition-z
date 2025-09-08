const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;

const std = @import("std");
const Allocator = std.mem.Allocator;

const assert = std.debug.assert;

pub fn upgradeStateToAltair(_: *CachedBeaconStateAllForks) CachedBeaconStateAllForks {
    @panic("unimplemented");
}
pub fn upgradeStateToBellatrix(_: *CachedBeaconStateAllForks) CachedBeaconStateAllForks {
    @panic("unimplemented");
}
pub fn upgradeStateToCapella(_: *CachedBeaconStateAllForks) CachedBeaconStateAllForks {
    @panic("unimplemented");
}
pub fn upgradeStateToDeneb(_: *CachedBeaconStateAllForks) CachedBeaconStateAllForks {
    @panic("unimplemented");
}
pub fn upgradeStateToElectra(_: *CachedBeaconStateAllForks) CachedBeaconStateAllForks {
    @panic("unimplemented");
}
pub fn upgradeStateToFulu(_: *CachedBeaconStateAllForks) CachedBeaconStateAllForks {
    @panic("unimplemented");
}
