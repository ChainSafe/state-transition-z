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
    altair: SyncCommitteeCache,

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

    pub fn computeSyncCommitteeCache(allocator: Allocator, sync_committee: SyncCommittee, pubkey_to_index: PubkeyIndexMap) !SyncCommitteeCacheAllForks {
        const cache = try SyncCommitteeCache.computeSyncCommitteeCache(allocator, sync_committee, pubkey_to_index);
        return SyncCommitteeCacheAllForks{ .altair = cache };
    }

    pub fn getSyncCommitteeCache(allocator: Allocator, indices: ValidatorIndices) !SyncCommitteeCacheAllForks {
        const cache = try SyncCommitteeCache.getSyncCommitteeCache(allocator, indices);
        return SyncCommitteeCacheAllForks{ .altair = cache };
    }

    pub fn deinit(self: *SyncCommitteeCacheAllForks) void {
        switch (self) {
            .phase0 => {},
            .altair => self.altair.deinit(),
        }
    }
};

/// this is for post-altair
const SyncCommitteeCache = struct {
    allocator: Allocator,

    validator_indices: ValidatorIndices,

    validator_index_map: SyncComitteeValidatorIndexMap,

    pub fn computeSyncCommitteeCache(allocator: Allocator, sync_committee: SyncCommittee, pubkey_to_index: PubkeyIndexMap) !SyncCommitteeCache {
        const validator_indices = try computeSyncCommitteeIndices(allocator, sync_committee, pubkey_to_index);
        return SyncCommitteeCache.getSyncCommitteeCache(allocator, validator_indices);
    }

    pub fn getSyncCommitteeCache(allocator: Allocator, indices: ValidatorIndices) !SyncCommitteeCache {
        const validator_indices = try cloneValidatorIndices(allocator, indices);
        const validator_index_map = try computeSyncCommitteeMap(allocator, validator_indices);
        return SyncCommitteeCache{
            .allocator = allocator,
            .validator_indices = validator_indices,
            .validator_index_map = validator_index_map,
        };
    }

    pub fn deinit(self: *SyncCommitteeCache) void {
        self.validator_indices.deinit();
        self.allocator.destroy(self.validator_indices);

        for (self.validator_index_map.valueIterator()) |value| {
            value.deinit();
        }
        self.validator_index_map.deinit();
        self.allocator.destroy(self);
    }
};

/// consumer should deinit each of the internal item inside SyncComitteeValidatorIndexMap
fn computeSyncCommitteeMap(allocator: Allocator, sync_committee_indices: *const ValidatorIndices) !SyncComitteeValidatorIndexMap {
    const map = SyncComitteeValidatorIndexMap.init(sync_committee_indices.allocator);
    for (sync_committee_indices.items, 0..) |validator_index, i| {
        const indices = try map.get(validator_index) orelse {
            return try SyncCommitteeIndices.init(allocator);
        };
        try indices.append(@intCast(i));
    }
    return map;
}

// consumer should destroy the created SyncCommitteeCache
// also deinit() before destroying
fn computeSyncCommitteeIndices(allocator: Allocator, sync_committee: *const SyncCommittee, pubkey_to_index: *const PubkeyIndexMap) !ValidatorIndices {
    const pubkeys = sync_committee.pubkeys;
    const validator_indices = ValidatorIndices.init(allocator);
    for (pubkeys) |pubkey| {
        const index = pubkey_to_index.get(pubkey[0..]) orelse return error.PubkeyNotFound;
        try validator_indices.append(@intCast(index));
    }
    return validator_indices;
}

// TODO: unit tests
