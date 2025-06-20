const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const PubkeyIndexMap = @import("../utils/pubkey_index_map.zig").PubkeyIndexMap;
const SyncCommittee = ssz.altair.SyncCommittee.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;

const SyncCommitteeIndices = std.ArrayList(u32);
const SyncComitteeValidatorIndexMap = std.AutoHashMap(ValidatorIndex, SyncCommitteeIndices);
const ValidatorIndices = std.ArrayList(ValidatorIndex);
const SyncCommitteeCache = struct {
    allocator: Allocator,

    validator_indices: *ValidatorIndices,

    validator_index_map: SyncComitteeValidatorIndexMap,

    // same to init
    // TODO: consider not to use this function and use the below getSyncCommitteeCache instead?
    // the reason is this function create managed validator_indices so it's inconsistent to getSyncCommitteeCache
    pub fn computeSyncCommitteeCache(allocator: Allocator, sync_committee: SyncCommittee, pubkey_to_index: PubkeyIndexMap) !*SyncCommitteeCache {
        const validator_indices = try computeSyncCommitteeIndices(allocator, sync_committee, pubkey_to_index);
        return SyncCommitteeCache.getSyncCommitteeCache(allocator, validator_indices);
    }

    pub fn getSyncCommitteeCache(allocator: Allocator, validator_indices: *const ValidatorIndices) !*SyncCommitteeCache {
        const cache = try allocator.create(SyncCommitteeCache);

        const validator_index_map = try computeSyncComitteeMap(allocator, validator_indices);
        cache.* = SyncCommitteeCache{
            .allocator = allocator,
            .validator_indices = validator_indices,
            .validator_index_map = validator_index_map,
        };

        return cache;
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
fn computeSyncComitteeMap(allocator: Allocator, sync_committee_indices: *const ValidatorIndices) !SyncComitteeValidatorIndexMap {
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
fn computeSyncCommitteeIndices(allocator: Allocator, sync_committee: *const SyncCommittee, pubkey_to_index: *const PubkeyIndexMap) !*ValidatorIndices {
    const pubkeys = sync_committee.pubkeys;
    const validator_indices = try allocator.create(ValidatorIndices);
    validator_indices.* = ValidatorIndices.init(allocator);
    for (pubkeys) |pubkey| {
        const index = pubkey_to_index.get(pubkey[0..]) orelse return error.PubkeyNotFound;
        try validator_indices.append(@intCast(index));
    }
    return validator_indices;
}

// TODO: unit tests
