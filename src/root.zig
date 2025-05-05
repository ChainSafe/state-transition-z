const std = @import("std");
const testing = std.testing;
pub const PubkeyIndexMap = @import("./pubkey_index_map.zig").PubkeyIndexMap;
pub const CommitteeIndices = @import("./committee_indices.zig");
pub const ComputeShuffledIndex = CommitteeIndices.ComputeShuffledIndex;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

test {
    testing.refAllDecls(@This());
}
