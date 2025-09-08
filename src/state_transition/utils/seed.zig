const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const digest = @import("./sha256.zig").digest;
const Epoch = ssz.primitive.Epoch.Type;
const Bytes32 = ssz.primitive.Bytes32.Type;
const DomainType = ssz.primitive.DomainType.Type;
const ForkSeq = @import("params").ForkSeq;
const params = @import("params");
const EPOCHS_PER_HISTORICAL_VECTOR = ssz.preset.EPOCHS_PER_HISTORICAL_VECTOR;
const MIN_SEED_LOOKAHEAD = ssz.preset.MIN_SEED_LOOKAHEAD;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const EffectiveBalanceIncrements = @import("../cache/effective_balance_increments.zig").EffectiveBalanceIncrements;
const computeStartSlotAtEpoch = @import("./epoch.zig").computeStartSlotAtEpoch;
const ComputeIndexUtils = @import("./committee_indices.zig").ComputeIndexUtils(ValidatorIndex);
const computeProposerIndex = ComputeIndexUtils.computeProposerIndex;
const computeSyncCommitteeIndices = ComputeIndexUtils.computeSyncCommitteeIndices;
const computeEpochAtSlot = @import("./epoch.zig").computeEpochAtSlot;
const ByteCount = @import("./committee_indices.zig").ByteCount;

pub fn computeProposers(allocator: Allocator, fork_seq: ForkSeq, epoch_seed: [32]u8, epoch: Epoch, active_indices: []const ValidatorIndex, effective_balance_increments: EffectiveBalanceIncrements, out: []ValidatorIndex) !void {
    const start_slot = computeStartSlotAtEpoch(epoch);
    for (start_slot..start_slot + preset.SLOTS_PER_EPOCH, 0..) |slot, i| {
        var slot_buf: [8]u8 = undefined;
        std.mem.writeInt(u64, &slot_buf, slot, .little);
        // epoch_seed is 32 bytes, slot_buf is 8 bytes
        var buffer: [40]u8 = [_]u8{0} ** (32 + 8);
        std.mem.copyForwards(u8, buffer[0..32], epoch_seed[0..]);
        std.mem.copyForwards(u8, buffer[32..], slot_buf[0..]);
        var seed: [32]u8 = undefined;
        digest(buffer[0..], &seed);

        const rand_byte_count: ByteCount = if (fork_seq.isPostElectra()) ByteCount.Two else ByteCount.One;
        const max_effective_balance: u64 = if (fork_seq.isPostElectra()) preset.MAX_EFFECTIVE_BALANCE_ELECTRA else preset.MAX_EFFECTIVE_BALANCE;
        out[i] = try computeProposerIndex(allocator, &seed, active_indices, effective_balance_increments.items, rand_byte_count, max_effective_balance, preset.EFFECTIVE_BALANCE_INCREMENT, preset.SHUFFLE_ROUND_COUNT);
    }
}

test "computeProposers - sanity" {
    const allocator = std.testing.allocator;
    const epoch_seed: [32]u8 = [_]u8{0} ** 32;
    var active_indices: [5]ValidatorIndex = .{ 0, 1, 2, 3, 4 };
    var effective_balance_increments = EffectiveBalanceIncrements.init(allocator);
    defer effective_balance_increments.deinit();
    for (0..active_indices.len) |_| {
        try effective_balance_increments.append(32);
    }
    var out: [preset.SLOTS_PER_EPOCH]ValidatorIndex = undefined;

    try computeProposers(allocator, ForkSeq.phase0, epoch_seed, 0, active_indices[0..], effective_balance_increments, &out);
    try computeProposers(allocator, ForkSeq.electra, epoch_seed, 0, active_indices[0..], effective_balance_increments, &out);
}

pub fn getNextSyncCommitteeIndices(allocator: Allocator, state: *const BeaconStateAllForks, active_indices: []const ValidatorIndex, effective_balance_increments: *const EffectiveBalanceIncrements, out: []ValidatorIndex) !void {
    const rand_byte_count: ByteCount = if (state.isPostElectra()) ByteCount.Two else ByteCount.One;
    const max_effective_balance: u64 = if (state.isPostElectra()) preset.MAX_EFFECTIVE_BALANCE_ELECTRA else preset.MAX_EFFECTIVE_BALANCE;

    const epoch = computeEpochAtSlot(state.slot() + 1);
    var seed: [32]u8 = undefined;
    try getSeed(state, epoch, params.DOMAIN_SYNC_COMMITTEE, &seed);
    try computeSyncCommitteeIndices(allocator, &seed, active_indices, effective_balance_increments.items, rand_byte_count, max_effective_balance, preset.EFFECTIVE_BALANCE_INCREMENT, preset.SHUFFLE_ROUND_COUNT, out);
}

pub fn getRandaoMix(state: *const BeaconStateAllForks, epoch: Epoch) Bytes32 {
    return state.randaoMixes()[epoch % EPOCHS_PER_HISTORICAL_VECTOR];
}

pub fn getSeed(state: *const BeaconStateAllForks, epoch: Epoch, domain_type: DomainType, out: *[32]u8) !void {
    const mix = getRandaoMix(state, epoch + EPOCHS_PER_HISTORICAL_VECTOR - MIN_SEED_LOOKAHEAD - 1);
    var epoch_buf: [8]u8 = undefined;
    std.mem.writeInt(u64, &epoch_buf, epoch, .little);
    var buffer = [_]u8{0} ** (ssz.primitive.DomainType.length + 8 + ssz.primitive.Bytes32.length);
    std.mem.copyForwards(u8, buffer[0..domain_type.len], domain_type[0..]);
    std.mem.copyForwards(u8, buffer[domain_type.len..(domain_type.len + 8)], epoch_buf[0..]);
    std.mem.copyForwards(u8, buffer[(domain_type.len + 8)..], mix[0..]);
    digest(buffer[0..], out);
}
