const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;
const builtin = @import("builtin");
const native_endian = builtin.target.cpu.arch.endian();
const Allocator = std.mem.Allocator;

pub const SEED_SIZE = 32;
const U32U32HashMap = std.AutoHashMap(u32, u32);
const U8SliceByU32 = std.AutoHashMap(u32, []const u8);
// note that AutoHashMap always copy data in put() api
// so value should be a pointer instead of U8SliceByU32 so that it can be freed
const U8SliceByU8ByU32 = std.AutoHashMap(u32, *U8SliceByU32);

/// a Zig implementation of https://github.com/ChainSafe/swap-or-not-shuffle/pull/5
pub const ComputeShuffledIndex = struct {
    // this ComputeShuffledIndex is always init() and deinit() inside consumer's function so use arena allocator here
    // to improve performance and implify deinit()
    arena: std.heap.ArenaAllocator,
    pivot_by_index: U32U32HashMap,
    source_by_position_by_index: U8SliceByU8ByU32,
    // 32 bytes seed + 1 byte i
    pivot_buffer: [33]u8,
    // 32 bytes seed + 1 byte i + 4 bytes positionDiv
    source_buffer: [37]u8,
    index_count: u32,
    rounds: u32,

    pub fn init(parent_allocator: Allocator, seed: []const u8, index_count: u32, rounds: u32) !ComputeShuffledIndex {
        if (seed.len != SEED_SIZE) {
            return error.InvalidSeedLen;
        }

        if (index_count == 0) {
            return error.InvalidIndexCount;
        }

        if (rounds == 0) {
            return error.InvalidRounds;
        }

        const arena = std.heap.ArenaAllocator.init(parent_allocator);

        const pivot_by_index = U32U32HashMap.init(parent_allocator);
        const source_by_position_by_index = U8SliceByU8ByU32.init(parent_allocator);

        var pivot_buffer: [33]u8 = [_]u8{0} ** 33;
        var source_buffer: [37]u8 = [_]u8{0} ** 37;
        @memcpy(pivot_buffer[0..SEED_SIZE], seed);
        @memcpy(source_buffer[0..SEED_SIZE], seed);

        return ComputeShuffledIndex{
            .arena = arena,
            .pivot_by_index = pivot_by_index,
            .source_by_position_by_index = source_by_position_by_index,
            .pivot_buffer = pivot_buffer,
            .source_buffer = source_buffer,
            .index_count = index_count,
            .rounds = rounds,
        };
    }

    pub fn deinit(self: *ComputeShuffledIndex) void {
        self.pivot_by_index.deinit();

        var it = self.source_by_position_by_index.iterator();
        while (it.next()) |entry| {
            var source_by_position = entry.value_ptr.*;
            // no need to loop through values and free the sources inside source_by_position thanks to arena
            source_by_position.deinit();
            // we create() source_by_position in the below get() api
            // but no need to destroy() it thanks to arena
        }

        self.source_by_position_by_index.deinit();

        // this needs to be the last step
        self.arena.deinit();
    }

    pub fn get(self: *ComputeShuffledIndex, index: u32) !u32 {
        var permuted = index;
        const allocator = self.arena.allocator();

        for (0..self.rounds) |i| {
            var pivot = self.pivot_by_index.get(@intCast(i));
            if (pivot == null) {
                self.pivot_buffer[SEED_SIZE] = @intCast(i % 256);
                var digest = [_]u8{0} ** 32;
                Sha256.hash(self.pivot_buffer[0..], digest[0..], .{});
                const u64Slice = std.mem.bytesAsSlice(u64, digest[0..8]);
                const u64_value = u64Slice[0];
                const le_value = if (native_endian == .big) @byteSwap(u64_value) else u64_value;
                pivot = @intCast(le_value % self.index_count);
            }

            const flip = (pivot.? + self.index_count - permuted) % self.index_count;
            const position = @max(permuted, flip);
            const position_div: u32 = position / 256;

            var source_by_position = self.source_by_position_by_index.get(@intCast(i));
            if (source_by_position == null) {
                const _source_by_position = try allocator.create(U8SliceByU32);
                _source_by_position.* = U8SliceByU32.init(allocator);
                try self.source_by_position_by_index.put(@intCast(i), _source_by_position);
                source_by_position = _source_by_position;
            }

            var source = source_by_position.?.get(position_div);
            if (source == null) {
                self.source_buffer[SEED_SIZE] = @intCast(i % 256);
                const u32Slice = std.mem.bytesAsSlice(u32, self.source_buffer[SEED_SIZE + 1 ..]);
                u32Slice[0] = if (native_endian == .big) @byteSwap(position_div) else position_div;

                const _source = try allocator.alloc(u8, 32);
                var hash = [_]u8{0} ** 32;
                Sha256.hash(self.source_buffer[0..], &hash, .{});
                @memcpy(_source, hash[0..]);
                try source_by_position.?.put(position_div, _source);
                source = _source;
            }

            const byte = source.?[@intCast(position % 256 / 8)];
            const bit = (byte >> @intCast(position % 8)) & 1;
            permuted = if (bit == 1) flip else permuted;
        }

        return permuted;
    }
};

const ByteCount = enum(u8) {
    One = 1,
    Two = 2,
};

/// the same to Rust implementation with "out" param to simplify memory allocation
fn get_committee_indices(allocator: Allocator, seed: []const u8, active_indices: []const u32, effective_balance_increments: []const u16, rand_byte_count: ByteCount, max_effective_balance: u64, effective_balance_increment: u32, rounds: u32, out: []u32) !void {
    const max_random_value: usize = if (rand_byte_count == .One) 0xff else 0xffff;
    const max_effective_balance_increment: usize = max_effective_balance / effective_balance_increment;

    const compute_shuffled_index = try ComputeShuffledIndex.init(allocator, seed, active_indices.len, rounds);
    const shuffled_result = U32U32HashMap.init(allocator);
    defer shuffled_result.deinit();

    var i: u32 = 0;
    var cached_hash_input = [_]u8{0} ** (32 + 8);
    // seed should have 32 bytes as checked in ComputeShuffledIndex.init
    @memcpy(cached_hash_input[0..32], seed);
    var cached_hash = [_]u8{0} ** 32;
    var next_committee_index: usize = 0;

    while (next_committee_index < out.len) {
        const index: u32 = @intCast(i % active_indices.len());
        var shuffled_index = try shuffled_result.get(index);
        if (shuffled_index == null) {
            const _shuffled_index = try compute_shuffled_index.get(index);
            try shuffled_result.put(index, _shuffled_index);
            shuffled_index = _shuffled_index;
        }
        const candidate_index = active_indices[@intCast(shuffled_index.?)];

        const hash_increment = if (rand_byte_count == .One) 32 else 16;
        if (i % hash_increment == 0) {
            const num_hash_increment = @divFloor(i, hash_increment);
            // suppose number of hash_increment always fit u32, the last 4 bytes of cached_hash_input is always 0
            // this is the same to below Rust implementation
            // cached_hash_input[32..36].copy_from_slice(&(i / hash_increment).to_le_bytes());
            const u32_slice = std.mem.bytesAsSlice(u32, cached_hash_input[32..36]);
            u32_slice[0] = if (native_endian == .big) @byteSwap(num_hash_increment) else num_hash_increment;
            Sha256.hash(cached_hash_input[0..], cached_hash[0..], .{});
        }

        const random_bytes = cached_hash;
        const random_value: usize = switch (rand_byte_count) {
            .One => {
                const offset: usize = @intCast(i % 32);
                return random_bytes[offset];
            },
            .Two => {
                const offset: usize = @intCast((i % 16) * 2);
                const value = std.mem.bytesAsValue(usize, random_bytes[offset..(offset + 2)]);
                return if (native_endian == .big) @byteSwap(value) else value;
            },
        };

        const candidate_effective_balance_increment = effective_balance_increments[@intCast(candidate_index)];
        if (candidate_effective_balance_increment * max_random_value >= max_effective_balance_increment * random_value) {
            out[next_committee_index] = candidate_index;
            next_committee_index += 1;
        }

        i += 1;
    }
}

test "ComputeShuffledIndex" {
    const allocator = std.testing.allocator;
    const seed = [_]u8{1} ** SEED_SIZE;
    const index_count = 1000;
    // SHUFFLE_ROUND_COUNT is 90 in ethereum mainnet
    const rounds = 90;

    var instance = try ComputeShuffledIndex.init(allocator, seed[0..], index_count, rounds);
    defer instance.deinit();

    const expected = [_]u32{ 789, 161, 541, 509, 498, 445, 270, 2, 505, 621, 947, 550, 338, 814, 285, 597, 169, 819, 644, 638, 751, 514, 750, 523, 303, 231, 391, 982, 409, 396, 641, 837 };

    for (0..index_count) |i| {
        if (i < 32) {
            const shuffled_index = try instance.get(@intCast(i));
            try std.testing.expectEqual(expected[i], shuffled_index);
        }
    }
}
