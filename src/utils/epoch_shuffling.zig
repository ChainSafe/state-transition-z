const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const BeaconStateAllForks = @import("../beacon_state.zig").BeaconStateAllForks;
const getSeed = @import("./seed.zig").getSeed;
const params = @import("../params.zig");
const innerShuffleList = @import("./shuffle.zig").innerShuffleList;
const Epoch = ssz.primitive.Epoch.Type;

// TODO: implement reference counting strategy
pub const EpochShuffling = struct {
    allocator: Allocator,

    epoch: Epoch,

    active_indices: []const u32,

    shuffling: []const u32,

    committees: []const []const []const u32,

    committees_per_slot: usize,

    pub fn init(allocator: Allocator, seed: [32]u8, epoch: Epoch, active_indices: []const u32) !EpochShuffling {
        const shuffling = try allocator.alloc(u32, active_indices.len);
        std.mem.copyForwards(u32, shuffling, active_indices);
        try unshuffleList(shuffling, seed[0..], preset.SHUFFLE_ROUND_COUNT);
        const committees = try buildCommitteesFromShuffling(allocator, shuffling);
        return EpochShuffling{
            .allocator = allocator,
            .epoch = epoch,
            .active_indices = active_indices,
            .shuffling = shuffling,
            .committees = committees,
            .committees_per_slot = computeCommitteeCount(active_indices.len),
        };
    }

    pub fn deinit(self: *EpochShuffling) void {
        for (self.committees) |committees_per_slot| {
            for (committees_per_slot) |committee| {
                self.allocator.free(committee);
            }
        }
        self.allocator.free(self.committees);
        self.allocator.destroy(self.shuffling);
    }

    fn buildCommitteesFromShuffling(allocator: Allocator, shuffling: []const u32) ![]const []const u32 {
        const active_validator_count = shuffling.len;
        const committees_per_slot = computeCommitteeCount(active_validator_count);
        const committee_count = committees_per_slot * preset.SLOTS_PER_EPOCH;

        const committees = try allocator.alloc([]const u32, committee_count);
        for (0..preset.SLOTS_PER_EPOCH) |slot| {
            const slot_committees = try allocator.alloc([]const u32, committees_per_slot);
            for (0..committees_per_slot) |committee_index| {
                const index = slot * committees_per_slot + committee_index;
                const start_offset = @divFloor(active_validator_count * index, committee_count);
                const end_offset = @divFloor(active_validator_count * (index + 1), committee_count);
                slot_committees[committee_index] = shuffling[start_offset..end_offset];
            }
            committees[slot] = slot_committees;
        }

        return committees;
    }
};

pub fn computeEpochShuffling(allocator: Allocator, state: BeaconStateAllForks, active_indices: []const u32, epoch: Epoch) !EpochShuffling {
    var seed = [_]u8{0} ** 32;
    try getSeed(state, epoch, params.DOMAIN_BEACON_ATTESTER, &seed);
    return EpochShuffling.init(allocator, seed, epoch, active_indices);
}

/// unshuffle the `active_indices` array in place synchronously
fn unshuffleList(active_indices: []u32, seed: []const u8, rounds: u8) !void {
    const forwards = false;
    return innerShuffleList(active_indices, seed, rounds, forwards);
}

fn computeCommitteeCount(active_validator_count: usize) usize {
    const validators_per_slot = @divFloor(active_validator_count, preset.SLOTS_PER_EPOCH);
    const committees_per_slot = @divFloor(validators_per_slot, preset.TARGET_COMMITTEE_SIZE);
    return @max(1, @min(preset.MAX_COMMITTEES_PER_SLOT, committees_per_slot));
}

// TODO: unit tests to make sure init/deinit works correctly
