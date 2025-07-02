const std = @import("std");
const testing = std.testing;

pub const processEth1DataReset = @import("epoch/process_eth1_data_reset.zig").processEth1DataReset;
// pub const computeSigningRoot = @import("utils/signining_root.zig").computeSigningRoot;
pub const BeaconBlock = @import("beacon_block.zig").BeaconBlock;
pub const BeaconStateAllForks = @import("beacon_state.zig").BeaconStateAllForks;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

// test "process epoch" {
//     const ssz = @import("consensus_types");
//     const phase0 = ssz.phase0;
//     const BeaconState = phase0.BeaconState;
//     var state = BeaconState.default_value;
//     processEth1DataReset(&state);
// }

test {
    testing.refAllDecls(@This());
}
