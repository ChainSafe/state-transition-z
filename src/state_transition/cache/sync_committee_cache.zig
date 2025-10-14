const std = @import("std");
const Allocator = std.mem.Allocator;
const preset = @import("preset").preset;
const ssz = @import("consensus_types");
const PubkeyIndexMap = @import("../stdx/pubkey_index_map.zig").PubkeyIndexMap(ValidatorIndex);
const SyncCommittee = ssz.altair.SyncCommittee.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const BLSPubkey = ssz.primitive.BLSPubkey.Type;

const SyncCommitteeIndices = std.ArrayList(u32);
const SyncComitteeValidatorIndexMap = std.AutoHashMap(ValidatorIndex, SyncCommitteeIndices);
const ReferenceCount = @import("../utils/reference_count.zig").ReferenceCount;

pub const SyncCommitteeCacheRc = ReferenceCount(SyncCommitteeCacheAllForks);

/// EpochCache is the only consumer of this cache but an instance of SyncCommitteeCacheAllForks is shared across EpochCache instances
/// no EpochCache instance takes the ownership of SyncCommitteeCacheAllForks instance
/// instead of that, we count on reference counting to deallocate the memory, see ReferenceCount() utility
pub const SyncCommitteeCacheAllForks = union(enum) {
    phase0: void,
    altair: *SyncCommitteeCache,

    pub fn getValidatorIndices(self: *const SyncCommitteeCacheAllForks) []ValidatorIndex {
        return switch (self.*) {
            .phase0 => @panic("phase0 does not have sync_committee"),
            .altair => |sync_committee| sync_committee.validator_indices,
        };
    }

    pub fn getValidatorIndexMap(self: *const SyncCommitteeCacheAllForks) SyncComitteeValidatorIndexMap {
        return switch (self) {
            .phase0 => @panic("phase0 does not have sync_committee"),
            .altair => self.altair.validator_index_map,
        };
    }

    pub fn initEmpty() SyncCommitteeCacheAllForks {
        return SyncCommitteeCacheAllForks{ .phase0 = {} };
    }

    pub fn initSyncCommittee(allocator: Allocator, sync_committee: *const SyncCommittee, pubkey_to_index: *const PubkeyIndexMap) !SyncCommitteeCacheAllForks {
        const cache = try SyncCommitteeCache.initSyncCommittee(allocator, sync_committee, pubkey_to_index);
        return SyncCommitteeCacheAllForks{ .altair = cache };
    }

    pub fn initValidatorIndices(allocator: Allocator, indices: []const ValidatorIndex) !SyncCommitteeCacheAllForks {
        const cloned_indices = try allocator.alloc(ValidatorIndex, indices.len);
        std.mem.copyForwards(ValidatorIndex, cloned_indices, indices);
        const cache = try SyncCommitteeCache.initValidatorIndices(allocator, cloned_indices);
        return SyncCommitteeCacheAllForks{ .altair = cache };
    }

    pub fn deinit(self: *SyncCommitteeCacheAllForks) void {
        switch (self.*) {
            .phase0 => {},
            .altair => |sync_committee_cache| sync_committee_cache.deinit(),
        }
    }
};

/// this is for post-altair
const SyncCommitteeCache = struct {
    allocator: Allocator,

    // this takes ownership of validator_indices, consumer needs to transfer ownership to this cache
    validator_indices: []ValidatorIndex,

    validator_index_map: *SyncComitteeValidatorIndexMap,

    pub fn initSyncCommittee(allocator: Allocator, sync_committee: *const SyncCommittee, pubkey_to_index: *const PubkeyIndexMap) !*SyncCommitteeCache {
        const validator_indices = try allocator.alloc(ValidatorIndex, sync_committee.pubkeys.len);
        try computeSyncCommitteeIndices(sync_committee, pubkey_to_index, validator_indices);
        return SyncCommitteeCache.initValidatorIndices(allocator, validator_indices);
    }

    pub fn initValidatorIndices(allocator: Allocator, validator_indices: []ValidatorIndex) !*SyncCommitteeCache {
        const validator_index_map = try allocator.create(SyncComitteeValidatorIndexMap);
        validator_index_map.* = SyncComitteeValidatorIndexMap.init(allocator);
        try computeSyncCommitteeMap(allocator, validator_indices, validator_index_map);
        const cache_ptr = try allocator.create(SyncCommitteeCache);
        cache_ptr.* = SyncCommitteeCache{
            .allocator = allocator,
            .validator_indices = validator_indices,
            .validator_index_map = validator_index_map,
        };
        return cache_ptr;
    }

    pub fn deinit(self: *SyncCommitteeCache) void {
        self.allocator.free(self.validator_indices);
        var value_iterator = self.validator_index_map.valueIterator();
        while (value_iterator.next()) |value| {
            value.deinit();
        }
        self.validator_index_map.deinit();
        self.allocator.destroy(self.validator_index_map);
        self.allocator.destroy(self);
    }
};

test "initSyncCommittee - sanity" {
    const allocator = std.testing.allocator;
    var sync_committee = SyncCommittee{
        .pubkeys = [_]BLSPubkey{
            [_]u8{1} ** 48,
        } ** preset.SYNC_COMMITTEE_SIZE,
        .aggregate_pubkey = [_]u8{2} ** 48,
    };

    const pubkey_index_map = try PubkeyIndexMap.init(allocator);
    defer pubkey_index_map.deinit();
    try pubkey_index_map.set(&sync_committee.pubkeys[0], 1000);

    var cache = try SyncCommitteeCacheAllForks.initSyncCommittee(allocator, &sync_committee, pubkey_index_map);
    defer cache.deinit();

    try std.testing.expectEqualSlices(
        ValidatorIndex,
        &[_]ValidatorIndex{1000} ** preset.SYNC_COMMITTEE_SIZE,
        cache.getValidatorIndices(),
    );
}

fn computeSyncCommitteeMap(allocator: Allocator, sync_committee_indices: []const ValidatorIndex, out: *SyncComitteeValidatorIndexMap) !void {
    for (sync_committee_indices, 0..) |validator_index, i| {
        var indices = out.getPtr(validator_index);
        if (indices == null) {
            try out.put(validator_index, SyncCommitteeIndices.init(allocator));
            indices = out.getPtr(validator_index) orelse unreachable;
        }

        try indices.?.append(@intCast(i));
    }
}

test computeSyncCommitteeMap {
    const allocator = std.testing.allocator;
    var map = try allocator.create(SyncComitteeValidatorIndexMap);
    map.* = SyncComitteeValidatorIndexMap.init(allocator);
    const indices = [_]ValidatorIndex{ 0, 0, 2, 2, 4, 5 };
    try computeSyncCommitteeMap(allocator, &indices, map);

    try std.testing.expectEqual(@as(u32, 4), map.count());
    try std.testing.expectEqualSlices(u32, &[_]u32{ 0, 1 }, map.get(0).?.items);
    try std.testing.expectEqualSlices(u32, &[_]u32{ 2, 3 }, map.get(2).?.items);
    try std.testing.expectEqualSlices(u32, &[_]u32{4}, map.get(4).?.items);
    try std.testing.expectEqualSlices(u32, &[_]u32{5}, map.get(5).?.items);

    defer {
        //deinit the map
        var value_iterator = map.valueIterator();
        while (value_iterator.next()) |value| {
            value.deinit();
        }
        map.deinit();
        allocator.destroy(map);
    }
}

fn computeSyncCommitteeIndices(sync_committee: *const SyncCommittee, pubkey_to_index: *const PubkeyIndexMap, out: []ValidatorIndex) !void {
    if (out.len != sync_committee.pubkeys.len) {
        return error.InvalidLength;
    }

    const pubkeys = sync_committee.pubkeys;
    for (pubkeys, 0..) |pubkey, i| {
        const index = pubkey_to_index.get(&pubkey) orelse return error.PubkeyNotFound;
        out[i] = @intCast(index);
    }
}

test computeSyncCommitteeIndices {
    var sync_committee = SyncCommittee{
        .pubkeys = [_]BLSPubkey{
            [_]u8{1} ** 48,
        } ** preset.SYNC_COMMITTEE_SIZE,
        .aggregate_pubkey = [_]u8{2} ** 48,
    };

    const allocator = std.testing.allocator;
    const pubkey_index_map = try PubkeyIndexMap.init(allocator);
    defer pubkey_index_map.deinit();
    try pubkey_index_map.set(&sync_committee.pubkeys[0], 1000);

    var out: [preset.SYNC_COMMITTEE_SIZE]ValidatorIndex = undefined;
    try computeSyncCommitteeIndices(&sync_committee, pubkey_index_map, &out);
    try std.testing.expectEqualSlices(
        ValidatorIndex,
        &[_]ValidatorIndex{1000} ** preset.SYNC_COMMITTEE_SIZE,
        &out,
    );
}
