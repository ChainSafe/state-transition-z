const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

pub fn digest(data: []const u8, out: *[32]u8) void {
    Sha256.hash(data, out, .{});
}
