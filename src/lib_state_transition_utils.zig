///! This file provides C-ABI functions for the PubkeyIndexMap and shuffle list utilities suitable for use in Bun.
const std = @import("std");
const Mutex = std.Thread.Mutex;
pub const PubkeyIndexMap = @import("utils/pubkey_index_map.zig").PubkeyIndexMap;
const PUBKEY_INDEX_MAP_KEY_SIZE = @import("utils/pubkey_index_map.zig").PUBKEY_INDEX_MAP_KEY_SIZE;
const innerShuffleList = @import("utils/shuffle.zig").innerShuffleList;
const SEED_SIZE = @import("utils/shuffle.zig").SEED_SIZE;
const committee_indices = @import("utils/committee_indices.zig");

pub const ErrorCode = struct {
    pub const Success: c_uint = 0;
    pub const InvalidInput: c_uint = 1;
    pub const Error: c_uint = 2;
    pub const TooManyThreadError: c_uint = 2;
    pub const MemoryError: c_uint = 3;
    pub const ThreadError: c_uint = 4;
    pub const InvalidPointerError: c_uint = 5;
    pub const Pending: c_uint = 10;
};

// this special index 4,294,967,295 is used to mark a not found
pub const NOT_FOUND_INDEX = 0xffffffff;
pub const ERROR_INDEX = 0xffffffff;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

/// C-ABI functions for PubkeyIndexMap
/// create an instance of PubkeyIndexMap
/// this returns a pointer to the instance in the heap which we can use in the following functions
export fn createPubkeyIndexMap() u64 {
    const allocator = gpa.allocator();
    const instance_ptr = PubkeyIndexMap.init(allocator) catch return 0;
    return @intFromPtr(instance_ptr);
}

/// destroy an instance of PubkeyIndexMap
export fn destroyPubkeyIndexMap(nbr_ptr: u64) void {
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    instance_ptr.deinit();
}

/// synchronize this special index to Bun
export fn getNotFoundIndex() c_uint {
    return NOT_FOUND_INDEX;
}

export fn getErrorIndex() c_uint {
    return ERROR_INDEX;
}

/// set a value to the specified PubkeyIndexMap instance
export fn pubkeyIndexMapSet(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint, value: c_uint) c_uint {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return ErrorCode.InvalidInput;
    }
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    instance_ptr.set(key[0..key_length], value) catch return ErrorCode.Error;
    return ErrorCode.Success;
}

/// get a value from the specified PubkeyIndexMap instance
export fn pubkeyIndexMapGet(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint) c_uint {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return NOT_FOUND_INDEX;
    }
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    const value = instance_ptr.get(key[0..key_length]) orelse return NOT_FOUND_INDEX;
    return value;
}

/// clear all values from the specified PubkeyIndexMap instance
export fn pubkeyIndexMapClear(nbr_ptr: u64) void {
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    instance_ptr.clear();
}

/// clone the specified PubkeyIndexMap instance
/// this returns a pointer to the new instance in the heap
export fn pubkeyIndexMapClone(nbr_ptr: u64) u64 {
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    const clone_ptr = instance_ptr.clone() catch return 0;
    return @intFromPtr(clone_ptr);
}

/// check if the specified PubkeyIndexMap instance has the specified key
export fn pubkeyIndexMapHas(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint) bool {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return false;
    }
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    return instance_ptr.has(key[0..key_length]);
}

/// delete the specified key from the specified PubkeyIndexMap instance
export fn pubkeyIndexMapDelete(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint) bool {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return false;
    }
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    return instance_ptr.delete(key[0..key_length]);
}

/// get the size of the specified PubkeyIndexMap instance
export fn pubkeyIndexMapSize(nbr_ptr: u64) c_uint {
    const instance_ptr: *PubkeyIndexMap = @ptrFromInt(nbr_ptr);
    return instance_ptr.size();
}

/// C-ABI functions for shuffle_list
/// on Ethereum consensus, shuffling is called once per epoch so this is more than enough
/// don't want to have too big value here so that we can detect issue sooner
const MAX_ASYNC_RESULT_SIZE = 4;
var mutex: Mutex = Mutex{};
var async_result_pointer_indices: [MAX_ASYNC_RESULT_SIZE]u64 = [_]u64{0} ** MAX_ASYNC_RESULT_SIZE;
var async_result_index: usize = 0;
const Status = enum {
    Pending,
    Done,
    Error,
};

/// object to store result from another thread and for bun to poll
const AsyncResult = struct {
    allocator: std.mem.Allocator,
    status: Status,
    mutex: Mutex,

    // can put any result here but no need for shuffling apis
    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const instance_ptr = try allocator.create(@This());
        instance_ptr.allocator = allocator;
        instance_ptr.status = Status.Pending;
        instance_ptr.mutex = Mutex{};
        return instance_ptr;
    }

    pub fn updateStatus(self: *@This(), new_status: Status) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.status = new_status;
    }

    // Get status safely while locking the mutex
    pub fn getStatus(self: *@This()) Status {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.status;
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

/// shuffle the `active_indices` array in place asynchronously
/// return an u64 which is the index within `MAX_ASYNC_RESULT_SIZE`
/// consumer needs to poll the AsyncResult via pollAsyncResult() using that index and
/// then release the AsyncResult via releaseAsyncResult() when done
export fn asyncShuffleList(active_indices: [*c]u32, len: usize, seed: [*c]const u8, seed_len: usize, rounds: u8) usize {
    const forwards = true;
    return doAsyncShuffleList(active_indices, len, seed, seed_len, rounds, forwards);
}

/// unshuffle the `active_indices` array in place asynchronously
/// return an u64 which is the index within `MAX_ASYNC_RESULT_SIZE`
/// consumer needs to poll the AsyncResult via pollAsyncResult() using that index and
/// then release the AsyncResult via releaseAsyncResult() when done
export fn asyncUnshuffleList(active_indices: [*c]u32, len: usize, seed: [*c]const u8, seed_len: usize, rounds: u8) usize {
    const forwards = false;
    return doAsyncShuffleList(active_indices, len, seed, seed_len, rounds, forwards);
}

fn doAsyncShuffleList(active_indices: [*c]u32, len: usize, seed: [*c]const u8, seed_len: usize, rounds: u8, forwards: bool) usize {
    if (len == 0 or seed_len == 0) {
        return ErrorCode.InvalidInput;
    }
    mutex.lock();
    defer mutex.unlock();
    // too many threads on-going for async result
    if (async_result_pointer_indices[(async_result_index + 1) % MAX_ASYNC_RESULT_SIZE] != 0) {
        return ErrorCode.TooManyThreadError;
    }
    async_result_index += 1;
    const pointer_index = async_result_index % MAX_ASYNC_RESULT_SIZE;

    const allocator = gpa.allocator();
    const result = AsyncResult.init(allocator) catch return ErrorCode.MemoryError;
    async_result_pointer_indices[pointer_index] = @intFromPtr(result);

    // this is called really sparsely, so we can just spawn new thread instead of using a thread pool like in blst-z
    const thread = std.Thread.spawn(.{}, struct {
        pub fn run(_active_indices: [*c]u32, _len: usize, _seed: [*c]const u8, _seed_len: usize, _rounds: u8, _forwards: bool, _result: *AsyncResult) void {
            innerShuffleList(
                _active_indices[0.._len],
                _seed[0.._seed_len],
                _rounds,
                _forwards,
            ) catch {
                _result.updateStatus(Status.Error);
                return;
            };
            _result.updateStatus(Status.Done);
        }
    }.run, .{ active_indices, len, seed, seed_len, rounds, forwards, result }) catch return ErrorCode.ThreadError;

    thread.detach();

    return pointer_index;
}

/// bun to store a pointer index
/// zig to get pointer u64 from async_result_pointer_indices and restore AsyncResult pointer
/// then release it
export fn releaseAsyncResult(pointer_index_param: usize) void {
    mutex.lock();
    defer mutex.unlock();
    const pointer_index = pointer_index_param % MAX_ASYNC_RESULT_SIZE;
    const async_result_ptr = async_result_pointer_indices[pointer_index];
    // avoid double-free
    if (async_result_ptr == 0) {
        return;
    }
    const result_ptr: *AsyncResult = @ptrFromInt(async_result_ptr);
    result_ptr.deinit();
    // native pointer cannot be 0 https://zig.guide/language-basics/pointers/
    async_result_pointer_indices[pointer_index] = 0;
}

/// bun to store a pointer index
/// zig to get pointer u64 from async_result_pointer_indices and restore AsyncResult pointer
/// then check value inside it
export fn pollAsyncResult(pointer_index_param: usize) c_uint {
    mutex.lock();
    defer mutex.unlock();
    const pointer_index = pointer_index_param % MAX_ASYNC_RESULT_SIZE;
    const async_result_ptr = async_result_pointer_indices[pointer_index];
    // native pointer cannot be 0 https://zig.guide/language-basics/pointers/
    if (async_result_ptr == 0) {
        return ErrorCode.InvalidPointerError;
    }
    const result_ptr: *AsyncResult = @ptrFromInt(async_result_ptr);
    const status = result_ptr.getStatus();
    if (status == Status.Done) {
        return ErrorCode.Success;
    } else if (status == Status.Error) {
        return ErrorCode.Error;
    }
    return ErrorCode.Pending;
}

/// shuffle the `active_indices` array in place synchronously
export fn shuffleList(active_indices: [*c]u32, len: usize, seed: [*c]u8, seed_len: usize, rounds: u8) c_uint {
    const forwards = true;
    return doShuffleList(active_indices, len, seed, seed_len, rounds, forwards);
}

/// unshuffle the `active_indices` array in place synchronously
export fn unshuffleList(active_indices: [*c]u32, len: usize, seed: [*c]u8, seed_len: usize, rounds: u8) c_uint {
    const forwards = false;
    return doShuffleList(active_indices, len, seed, seed_len, rounds, forwards);
}

export fn doShuffleList(active_indices: [*c]u32, len: usize, seed: [*c]u8, seed_len: usize, rounds: u8, forwards: bool) c_uint {
    if (len == 0 or seed_len == 0) {
        return ErrorCode.InvalidInput;
    }

    innerShuffleList(
        active_indices[0..len],
        seed[0..seed_len],
        rounds,
        forwards,
    ) catch return ErrorCode.Error;
    return ErrorCode.Success;
}

export fn computeProposerIndexElectra(seed: [*c]u8, seed_len: usize, active_indices: [*c]u32, active_indices_len: usize, effective_balance_increments: [*c]u16, effective_balance_increments_len: usize, max_effective_balance_electra: u64, effective_balance_increment: u32, rounds: u32) u32 {
    const allocator = gpa.allocator();
    // TODO: is it better to define a Result struct with code and value
    const proposer_index = committee_indices.computeProposerIndexElectra(allocator, seed[0..seed_len], active_indices[0..active_indices_len], effective_balance_increments[0..effective_balance_increments_len], max_effective_balance_electra, effective_balance_increment, rounds) catch return ERROR_INDEX;
    return proposer_index;
}

export fn computeProposerIndex(seed: [*c]u8, seed_len: usize, active_indices: [*c]u32, active_indices_len: usize, effective_balance_increments: [*c]u16, effective_balance_increments_len: usize, rand_byte_count: committee_indices.ByteCount, max_effective_balance: u64, effective_balance_increment: u32, rounds: u32) u32 {
    const allocator = gpa.allocator();
    // TODO: is it better to define a Result struct with code and value
    const proposer_index = committee_indices.computeProposerIndex(allocator, seed[0..seed_len], active_indices[0..active_indices_len], effective_balance_increments[0..effective_balance_increments_len], rand_byte_count, max_effective_balance, effective_balance_increment, rounds) catch return ERROR_INDEX;
    return proposer_index;
}

export fn computeSyncCommitteeIndicesElectra(seed: [*c]u8, seed_len: usize, active_indices: [*c]u32, active_indices_len: usize, effective_balance_increments: [*c]u16, effective_balance_increments_len: usize, max_effective_balance_electra: u64, effective_balance_increment: u32, rounds: u32, out: [*c]u32, out_len: usize) c_uint {
    const allocator = gpa.allocator();
    committee_indices.computeSyncCommitteeIndicesElectra(allocator, seed[0..seed_len], active_indices[0..active_indices_len], effective_balance_increments[0..effective_balance_increments_len], max_effective_balance_electra, effective_balance_increment, rounds, out[0..out_len]) catch return ErrorCode.Error;
    return ErrorCode.Success;
}

export fn computeSyncCommitteeIndices(seed: [*c]u8, seed_len: usize, active_indices: [*c]u32, active_indices_len: usize, effective_balance_increments: [*c]u16, effective_balance_increments_len: usize, rand_byte_count: committee_indices.ByteCount, max_effective_balance: u64, effective_balance_increment: u32, rounds: u32, out: [*c]u32, out_len: usize) c_uint {
    const allocator = gpa.allocator();
    committee_indices.computeSyncCommitteeIndices(allocator, seed[0..seed_len], active_indices[0..active_indices_len], effective_balance_increments[0..effective_balance_increments_len], rand_byte_count, max_effective_balance, effective_balance_increment, rounds, out[0..out_len]) catch return ErrorCode.Error;
    return ErrorCode.Success;
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

// more tests for async shuffle and unshuffle at bun side
test "asyncShuffleList - issue single thread and poll the result" {
    var input = [_]u32{ 0, 1, 2, 3, 4, 5, 6, 7, 8 };
    var seed = [_]u8{0} ** SEED_SIZE;
    const rounds = 32;

    const pointer_index = asyncUnshuffleList(&input[0], input.len, &seed[0], seed.len, rounds);
    defer releaseAsyncResult(pointer_index);

    // poll the AsyncResult, this should happen in less than 100ms or the test wil fail
    const start = std.time.milliTimestamp();
    while (std.time.milliTimestamp() - start < 100) {
        const status = pollAsyncResult(pointer_index);
        if (status == ErrorCode.Success) {
            const expected = [_]u32{ 6, 2, 3, 5, 1, 7, 8, 0, 4 };
            try std.testing.expectEqualSlices(u32, expected[0..], input[0..]);
            return;
        }
        std.time.sleep(10 * std.time.ns_per_ms);
    }

    // after 100ms and still pending, this is a failure
    try std.testing.expect(false);
}
