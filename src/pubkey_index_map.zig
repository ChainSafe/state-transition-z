const std = @import("std");
const Allocator = std.mem.Allocator;

pub const PUBKEY_INDEX_MAP_KEY_SIZE = 48;
pub const Val = u32;
pub const Key = [PUBKEY_INDEX_MAP_KEY_SIZE]u8;
const AutoHashMap = std.AutoHashMap(Key, Val);

/// a generic implementation for both zig application and Bun ffi
pub const PubkeyIndexMap = struct {
    map: AutoHashMap,

    pub fn init(allocator: Allocator) !*PubkeyIndexMap {
        const instance = try allocator.create(PubkeyIndexMap);
        instance.* = .{ .map = AutoHashMap.init(allocator) };
        return instance;
    }

    pub fn deinit(self: *PubkeyIndexMap) void {
        const allocator = self.map.allocator;
        self.map.deinit();
        allocator.destroy(self);
    }

    pub fn set(self: *PubkeyIndexMap, key: []const u8, value: Val) !void {
        var fixed_key: Key = undefined;
        @memcpy(&fixed_key, key);
        try self.map.put(fixed_key, value);
    }

    pub fn get(self: *const PubkeyIndexMap, key: []const u8) ?Val {
        var fixed_key: Key = undefined;
        @memcpy(&fixed_key, key);
        return self.map.get(fixed_key);
    }

    pub fn has(self: *const PubkeyIndexMap, key: []const u8) bool {
        var fixed_key: Key = undefined;
        @memcpy(&fixed_key, key);
        return self.map.getKey(fixed_key) != null;
    }

    pub fn delete(self: *PubkeyIndexMap, key: []const u8) bool {
        var fixed_key: Key = undefined;
        @memcpy(&fixed_key, key);
        return self.map.remove(fixed_key);
    }

    pub fn size(self: *const PubkeyIndexMap) u32 {
        return self.map.count();
    }

    pub fn clear(self: *PubkeyIndexMap) void {
        self.map.clearAndFree();
    }

    pub fn clone(self: *const PubkeyIndexMap) !*PubkeyIndexMap {
        const allocator = self.map.allocator;
        const instance = try allocator.create(PubkeyIndexMap);
        instance.* = .{ .map = try self.map.clone() };
        return instance;
    }
};

test "PubkeyIndexMap" {
    const allocator = std.testing.allocator;
    const instance = try PubkeyIndexMap.init(allocator);
    defer instance.deinit();

    var key: [PUBKEY_INDEX_MAP_KEY_SIZE]u8 = [_]u8{5} ** PUBKEY_INDEX_MAP_KEY_SIZE;
    const value = 42;
    try instance.set(key[0..], value);
    var result = instance.get(key[0..]);
    if (result) |v| {
        try std.testing.expectEqual(v, value);
    } else {
        try std.testing.expect(false);
    }

    // C pointer
    var key_ptr: [*c]const u8 = key[0..].ptr;
    result = instance.get(key_ptr[0..key.len]);
    if (result) |v| {
        try std.testing.expectEqual(v, value);
    } else {
        try std.testing.expect(false);
    }

    key[1] = 1; // change key
    result = instance.get(key[0..]);
    try std.testing.expect(result == null);

    // C pointer
    result = instance.get(key_ptr[0..key.len]);
    try std.testing.expect(result == null);

    // new instance with same value
    const key2: [PUBKEY_INDEX_MAP_KEY_SIZE]u8 = [_]u8{5} ** PUBKEY_INDEX_MAP_KEY_SIZE;
    result = instance.get(key2[0..]);
    if (result) |v| {
        try std.testing.expectEqual(v, value);
    } else {
        try std.testing.expect(false);
    }

    // C pointer
    key_ptr = key2[0..].ptr;
    result = instance.get(key_ptr[0..key.len]);
    if (result) |v| {
        try std.testing.expectEqual(v, value);
    } else {
        try std.testing.expect(false);
    }

    // has
    try std.testing.expect(instance.has(key_ptr[0..key.len]));

    // size
    try std.testing.expectEqual(1, instance.size());
    try instance.set(([_]u8{255} ** PUBKEY_INDEX_MAP_KEY_SIZE)[0..], 100);
    try std.testing.expectEqual(2, instance.size());

    // delete
    var del_res = instance.delete(([_]u8{254} ** PUBKEY_INDEX_MAP_KEY_SIZE)[0..]);
    try std.testing.expect(!del_res);
    del_res = instance.delete(([_]u8{255} ** PUBKEY_INDEX_MAP_KEY_SIZE)[0..]);
    try std.testing.expect(del_res);
    try std.testing.expectEqual(1, instance.size());

    // clone
    const clone_instance = try instance.clone();
    defer clone_instance.deinit();
    try std.testing.expectEqual(1, clone_instance.size());
    result = clone_instance.get(key_ptr[0..key.len]);
    if (result) |v| {
        try std.testing.expectEqual(v, value);
    } else {
        try std.testing.expect(false);
    }

    // clear
    instance.clear();
    try std.testing.expectEqual(0, instance.size());

    // cloned instance is not affected
    try std.testing.expectEqual(1, clone_instance.size());
}
