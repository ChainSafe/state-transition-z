const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const preset = ssz.preset;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const getSeed = @import("./seed.zig").getSeed;
const params = @import("params");
const innerShuffleList = @import("./shuffle.zig").innerShuffleList;
const Epoch = ssz.primitive.Epoch.Type;
const getReferenceCount = @import("./reference_count.zig").getReferenceCount;
const ValidatorIndices = @import("../type.zig").ValidatorIndices;

pub const EpochShufflingRc = getReferenceCount(*EpochShuffling);

/// EpochCache is the only consumer of this cache but an instance of EpochShuffling is shared across EpochCache instances
/// no EpochCache instance takes the ownership of shuffling
/// instead of that, we count on reference counting to deallocate the memory, see getReferenceCount() utility
pub const EpochShuffling = struct {
    allocator: Allocator,

    epoch: Epoch,
    // EpochShuffling takes ownership of all properties below
    active_indices: []ValidatorIndex,

    shuffling: []const u32,

    /// the internal last-level committee shared the same data with `shuffling` so don't need to free it
    committees: []const []const []const u32,

    committees_per_slot: usize,

    pub fn init(allocator: Allocator, seed: [32]u8, epoch: Epoch, active_indices: []ValidatorIndex) !*EpochShuffling {
        const shuffling = try allocator.alloc(u32, active_indices.len);
        // TODO: unshuffleList should support a comptime parameter for the type of indices
        // std.mem.copyForwards(u32, shuffling, active_indices.items);
        for (active_indices, 0..) |validator_index, i| {
            shuffling[i] = @intCast(validator_index);
        }
        try unshuffleList(shuffling, seed[0..], preset.SHUFFLE_ROUND_COUNT);
        const committees = try buildCommitteesFromShuffling(allocator, shuffling);

        const epoch_shuffling_ptr = try allocator.create(EpochShuffling);
        epoch_shuffling_ptr.* = EpochShuffling{
            .allocator = allocator,
            .epoch = epoch,
            .active_indices = active_indices,
            .shuffling = shuffling,
            .committees = committees,
            .committees_per_slot = computeCommitteeCount(active_indices.len),
        };

        return epoch_shuffling_ptr;
    }

    pub fn deinit(self: *EpochShuffling) void {
        for (self.committees) |committees_per_slot| {
            // no need to free each committee since they are slices of `shuffling`
            self.allocator.free(committees_per_slot);
        }
        self.allocator.free(self.active_indices);
        self.allocator.free(self.shuffling);
        self.allocator.free(self.committees);
    }

    fn buildCommitteesFromShuffling(allocator: Allocator, shuffling: []const u32) ![]const []const []const u32 {
        const active_validator_count = shuffling.len;
        const committees_per_slot = computeCommitteeCount(active_validator_count);
        const committee_count = committees_per_slot * preset.SLOTS_PER_EPOCH;

        const committees = try allocator.alloc([]const []const u32, committee_count);
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

/// active_indices is allocated at consumer side and transfer ownership to EpochShuffling
pub fn computeEpochShuffling(allocator: Allocator, state: *const BeaconStateAllForks, active_indices: []ValidatorIndex, epoch: Epoch) !*EpochShuffling {
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
