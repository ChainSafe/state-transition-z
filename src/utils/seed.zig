const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const digest = @import("./sha256.zig").digest;
const Epoch = ssz.primitive.Epoch.Type;
const Bytes32 = ssz.primitive.Bytes32.Type;
const DomainType = ssz.primitive.DomainType.Type;
const ForkSeq = @import("../config.zig").ForkSeq;
const params = @import("../params.zig");
const EPOCHS_PER_HISTORICAL_VECTOR = ssz.preset.EPOCHS_PER_HISTORICAL_VECTOR;
const MIN_SEED_LOOKAHEAD = ssz.preset.MIN_SEED_LOOKAHEAD;
const ValidatorIndices = @import("../type.zig").ValidatorIndices;
const ValidatorIndex = @import("../type.zig").ValidatorIndex;
const EffectiveBalanceIncrements = @import("../cache/effective_balance_increments.zig").EffectiveBalanceIncrements;
const computeStartSlotAtEpoch = @import("./epoch.zig").computeStartSlotAtEpoch;
const computeProposerIndex = @import("./committee_indices.zig").computeProposerIndex;
const computeSyncCommitteeIndices = @import("./committee_indices.zig").computeSyncCommitteeIndices;
const computeEpochAtSlot = @import("./epoch.zig").computeEpochAtSlot;

pub fn computeProposers(allocator: Allocator, fork: ForkSeq, epoch_seed: [32]u8, epoch: Epoch, active_indices: []ValidatorIndex, effective_balance_increments: EffectiveBalanceIncrements, out: []u32) !void {
    const start_slot = computeStartSlotAtEpoch(epoch);
    for (start_slot..start_slot + preset.SLOTS_PER_EPOCH, 0..) |slot, i| {
        const slot_buf: [8]u8 = undefined;
        std.mem.writeInt(u64, &slot_buf, slot, .little);
        // epoch_seed is 32 bytes, slot_buf is 8 bytes
        var buffer: [40]u8 = [_]u8{0} ** (32 + 8);
        std.mem.copyForwards(u8, buffer[0..32], epoch_seed[0..]);
        std.mem.copyForwards(u8, buffer[32..], slot_buf[0..]);
        var seed: [32]u8 = undefined;
        digest(buffer[0..], &seed);

        const rand_byte_count = if (fork >= ForkSeq.electra) 2 else 1;
        const max_effective_balance = if (fork >= ForkSeq.electra) preset.MAX_EFFECTIVE_BALANCE_PRE_ELECTRA else preset.MAX_EFFECTIVE_BALANCE;
        // TODO: generalize computeProposerIndex to handle both u32 and u64
        out[i] = try computeProposerIndex(allocator, seed, active_indices, effective_balance_increments.items, rand_byte_count, max_effective_balance, preset.EFFECTIVE_BALANCE_INCREMENT, preset.SHUFFLE_ROUND_COUNT);
    }
}

pub fn getNextSyncCommitteeIndices(allocator: Allocator, fork: ForkSeq, state: *const BeaconStateAllForks, active_indices: []ValidatorIndex, effective_balance_increments: EffectiveBalanceIncrements, out: []u32) !void {
    const rand_byte_count = if (fork >= ForkSeq.electra) 2 else 1;
    const max_effective_balance = if (fork >= ForkSeq.electra) preset.MAX_EFFECTIVE_BALANCE_PRE_ELECTRA else preset.MAX_EFFECTIVE_BALANCE;

    const epoch = computeEpochAtSlot(state.getSlot() + 1);
    var seed: [32]u8 = undefined;
    try getSeed(state, epoch, params.DOMAIN_SYNC_COMMITTEE, &seed);
    try computeSyncCommitteeIndices(allocator, seed, active_indices, effective_balance_increments.items, rand_byte_count, max_effective_balance, preset.EFFECTIVE_BALANCE_INCREMENT, preset.SHUFFLE_ROUND_COUNT, out);
}

pub fn getRandaoMix(state: BeaconStateAllForks, epoch: Epoch) Bytes32 {
    return state.getRanDaoMix(epoch % EPOCHS_PER_HISTORICAL_VECTOR);
}

pub fn getSeed(state: BeaconStateAllForks, epoch: Epoch, domain_type: DomainType, out: *[32]u8) !void {
    const mix = getRandaoMix(state, epoch + EPOCHS_PER_HISTORICAL_VECTOR - MIN_SEED_LOOKAHEAD - 1);
    var epoch_buf: [8]u8 = undefined;
    std.mem.writeInt(u64, &epoch_buf, epoch, .little);
    var buffer = [_]u8{0} ** (DomainType.len + 8 + Bytes32.len);
    std.mem.copyForwards(u8, out[0..domain_type.len], domain_type[0..]);
    std.mem.copyForwards(u8, out[domain_type.len .. domain_type.len + 8], epoch_buf[0..]);
    std.mem.copyForwards(u8, out[domain_type.len + 8 ..], mix[0..]);
    digest(buffer[0..], out);
}
