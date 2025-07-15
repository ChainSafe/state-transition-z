const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const PubkeyIndexMap = @import("../utils/pubkey_index_map.zig").PubkeyIndexMap;
const SyncCommittee = ssz.altair.SyncCommittee.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;

const SyncCommitteeIndices = std.ArrayList(u32);
const SyncComitteeValidatorIndexMap = std.AutoHashMap(ValidatorIndex, SyncCommitteeIndices);
const ValidatorIndices = @import("../type.zig").ValidatorIndices;
const cloneValidatorIndices = @import("../type.zig").cloneValidatorIndices;
const getReferenceCount = @import("../utils/reference_count.zig").getReferenceCount;

pub const SyncCommitteeCacheRc = getReferenceCount(SyncCommitteeCacheAllForks);

/// EpochCache is the only consumer of this cache but an instance of SyncCommitteeCacheAllForks is shared across EpochCache instances
/// no EpochCache instance takes the ownership of SyncCommitteeCacheAllForks instance
/// instead of that, we count on reference counting to deallocate the memory, see getReferenceCount() utility
pub const SyncCommitteeCacheAllForks = union(enum) {
    phase0: void,
    altair: *SyncCommitteeCache,

    pub fn getValidatorIndices(self: *const SyncCommitteeCacheAllForks) ValidatorIndices {
        return switch (self) {
            .phase0 => @panic("phase0 does not have sync_committee"),
            .altair => self.altair.validator_indices,
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

    pub fn computeSyncCommitteeCache(allocator: Allocator, sync_committee: *const SyncCommittee, pubkey_to_index: *const PubkeyIndexMap) !SyncCommitteeCacheAllForks {
        const cache = try SyncCommitteeCache.computeSyncCommitteeCache(allocator, sync_committee, pubkey_to_index);
        return SyncCommitteeCacheAllForks{ .altair = cache };
    }

    pub fn getSyncCommitteeCache(allocator: Allocator, indices: ValidatorIndices) !SyncCommitteeCacheAllForks {
        const cache = try SyncCommitteeCache.getSyncCommitteeCache(allocator, indices);
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

    pub fn computeSyncCommitteeCache(allocator: Allocator, sync_committee: *const SyncCommittee, pubkey_to_index: *const PubkeyIndexMap) !*SyncCommitteeCache {
        const validator_indices = try allocator.alloc(ValidatorIndex, sync_committee.pubkeys.len);
        try computeSyncCommitteeIndices(sync_committee, pubkey_to_index, validator_indices);
        return SyncCommitteeCache.getSyncCommitteeCache(allocator, validator_indices);
    }

    pub fn getSyncCommitteeCache(allocator: Allocator, validator_indices: []ValidatorIndex) !*SyncCommitteeCache {
        const validator_index_map = try computeSyncCommitteeMap(allocator, validator_indices);
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

/// consumer should deinit each of the internal item inside SyncComitteeValidatorIndexMap
fn computeSyncCommitteeMap(allocator: Allocator, sync_committee_indices: []ValidatorIndex) !*SyncComitteeValidatorIndexMap {
    var map = SyncComitteeValidatorIndexMap.init(allocator);
    for (sync_committee_indices, 0..) |validator_index, i| {
        var indices = map.get(validator_index);
        if (indices == null) {
            indices = SyncCommitteeIndices.init(allocator);
            try map.put(validator_index, indices.?);
        }
        try indices.?.append(@intCast(i));
    }

    const map_ptr = try allocator.create(SyncComitteeValidatorIndexMap);
    map_ptr.* = map;
    return map_ptr;
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

// TODO: unit tests
