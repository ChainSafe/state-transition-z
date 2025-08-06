const std = @import("std");
const ssz = @import("consensus_types");
const digest = @import("./sha256.zig").digest;
const Root = ssz.primitive.Root.Type;

pub fn verifyMerkleBranch(leaf: Root, proof: *const [33]Root, depth: usize, index: usize, root: Root) bool {
    var value = leaf;
    var tmp: [64]u8 = undefined;
    for (0..depth) |i| {
        if (@divFloor(index, 2 ** i) % 2 != 0) {
            @memcpy(tmp, proof[i]);
            @memcpy(tmp[32..], value);
        } else {
            @memcpy(tmp, value);
            @memcpy(tmp[32..], proof[i]);
        }
        digest(&tmp, &value);
    }
    return std.mem.allEqual(u8, &root, &value);
}

// TODO: unit tests
