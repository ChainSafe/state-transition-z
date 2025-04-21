const std = @import("std");
pub const PubkeyIndexMap = @import("pubkey_index_map.zig").PubkeyIndexMap;
const PUBKEY_INDEX_MAP_KEY_SIZE = @import("pubkey_index_map.zig").PUBKEY_INDEX_MAP_KEY_SIZE;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const STATE_TRANSITION_UTILS_SUCCESS: c_uint = 0;
const STATE_TRANSITION_UTILS_INVALID_INPUTS: c_uint = 1;
const STATE_TRANSITION_UTILS_ERROR: c_uint = 2;

export fn createPubkeyIndexMap() u64 {
    const allocator = gpa.allocator();
    const instance_ptr = PubkeyIndexMap.init(allocator) catch return 0;
    return @intFromPtr(instance_ptr);
}

export fn destroyPubkeyIndexMap(nbr_ptr: u64) void {
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    instance_ptr.deinit();
}

// TODO: use correct returned error code
export fn pubkeyIndexMapSet(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint, value: c_uint) c_uint {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return STATE_TRANSITION_UTILS_INVALID_INPUTS;
    }
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    instance_ptr.set(key[0..key_length], value) catch return STATE_TRANSITION_UTILS_ERROR;
    return STATE_TRANSITION_UTILS_SUCCESS;
}

export fn pubkeyIndexMapGet(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint) c_uint {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return 0xffffffff;
    }
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    // not found is 0xffffffff
    const value = instance_ptr.get(key[0..key_length]) orelse return 0xffffffff;
    return value;
}

export fn pubkeyIndexMapClear(nbr_ptr: u64) void {
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    instance_ptr.clear();
}

export fn pubkeyIndexMapClone(nbr_ptr: u64) u64 {
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    const clone_ptr = instance_ptr.clone() catch return 0;
    return @intFromPtr(clone_ptr);
}

export fn pubkeyIndexMapHas(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint) bool {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return false;
    }
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    return instance_ptr.has(key[0..key_length]);
}

export fn pubkeyIndexMapDelete(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint) bool {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return false;
    }
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    return instance_ptr.delete(key[0..key_length]);
}

export fn pubkeyIndexMapSize(nbr_ptr: u64) c_uint {
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    return instance_ptr.size();
}

test "PubkeyIndexMap C-ABI functions" {
    const map = createPubkeyIndexMap();
    defer destroyPubkeyIndexMap(map);

    var key: [PUBKEY_INDEX_MAP_KEY_SIZE]u8 = [_]u8{5} ** PUBKEY_INDEX_MAP_KEY_SIZE;
    const value = 42;
    _ = pubkeyIndexMapSet(map, &key[0], key.len, value);
    var result = pubkeyIndexMapGet(map, &key[0], key.len);
    try std.testing.expect(result == value);

    // change key
    key[1] = 1;
    result = pubkeyIndexMapGet(map, &key[0], key.len);
    try std.testing.expect(result == 0xffffffff);

    // new instance with same value
    const key2: [PUBKEY_INDEX_MAP_KEY_SIZE]u8 = [_]u8{5} ** PUBKEY_INDEX_MAP_KEY_SIZE;
    result = pubkeyIndexMapGet(map, &key2[0], key2.len);
    try std.testing.expect(result == value);

    // has
    try std.testing.expect(pubkeyIndexMapHas(map, &key2[0], key2.len));

    // size
    try std.testing.expectEqual(1, pubkeyIndexMapSize(map));
    const new_key = ([_]u8{255} ** PUBKEY_INDEX_MAP_KEY_SIZE)[0..];
    _ = pubkeyIndexMapSet(map, &new_key[0], new_key.len, 100);
    try std.testing.expectEqual(2, pubkeyIndexMapSize(map));

    // delete
    const missing_key = ([_]u8{254} ** PUBKEY_INDEX_MAP_KEY_SIZE)[0..];
    var del_res = pubkeyIndexMapDelete(map, &missing_key[0], missing_key.len);
    try std.testing.expect(!del_res);
    del_res = pubkeyIndexMapDelete(map, &new_key[0], new_key.len);
    try std.testing.expect(del_res);
    try std.testing.expectEqual(1, pubkeyIndexMapSize(map));

    // clone
    const cloned_map = pubkeyIndexMapClone(map);
    defer destroyPubkeyIndexMap(cloned_map);
    try std.testing.expectEqual(1, pubkeyIndexMapSize(cloned_map));
    result = pubkeyIndexMapGet(cloned_map, &key2[0], key2.len);
    try std.testing.expect(result == value);

    // clear
    pubkeyIndexMapClear(map);
    try std.testing.expectEqual(0, pubkeyIndexMapSize(map));

    // cloned instance is not affected
    try std.testing.expectEqual(1, pubkeyIndexMapSize(cloned_map));
}
