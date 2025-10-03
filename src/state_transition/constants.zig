const std = @import("std");
pub const ZERO_HASH = [_]u8{0} ** 32;
pub const EMPTY_SIGNATURE = [_]u8{0} ** 96;
pub const SECONDS_PER_DAY = 86400;
pub const BASE_REWARDS_PER_EPOCH = 4;

pub const G2_POINT_AT_INFINITY = blk: {
    const hex_string = "c000000000000000000000000000000000000000000000000000000000000000" ++ "0000000000000000000000000000000000000000000000000000000000000000" ++ "0000000000000000000000000000000000000000000000000000000000000000";
    const byte_array_len = hex_string.len / 2;
    var bytes: [byte_array_len]u8 = undefined;
    _ = std.fmt.hexToBytes(&bytes, hex_string) catch unreachable;
    break :blk bytes;
};
