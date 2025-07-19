const std = @import("std");
const Allocator = std.mem.Allocator;
const types = @import("../type.zig");
const Epoch = types.Epoch;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const computeStartSlotAtEpoch = @import("../utils/epoch.zig").computeStartSlotAtEpoch;
const getBlockRootAtSlot = @import("../utils/block_root.zig").getBlockRootAtSlot;
const ssz = @import("consensus_types");
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const phase0 = ssz.phase0;
const PendingAttestation = ssz.phase0.PendingAttestation.Type;

pub fn processPendingAttestations(allocator: Allocator, cached_state: *CachedBeaconStateAllForks, proposer_indices: []usize, validator_count: usize, inclusion_delays: []usize, flags: []u8, attestations: []const PendingAttestation, epoch: Epoch, source_flag: u8, target_flag: u8, head_flag: u8) !void {
    const epoch_cache = cached_state.getEpochCache();
    const state = cached_state.state;
    const state_slot = state.getSlot();
    const prev_epoch = epoch_cache.previous_shuffling.get().epoch;
    if (attestations.len == 0) {
        return;
    }

    const actual_target_block_root = try getBlockRootAtSlot(state, computeStartSlotAtEpoch(epoch));
    for (0..attestations.len) |i| {
        const att = attestations[i];
        // Ignore empty BitArray, from spec test minimal/phase0/epoch_processing/participation_record_updates updated_participation_record
        // See https://github.com/ethereum/consensus-specs/issues/2825
        if (att.aggregation_bits.bit_len == 0) {
            continue;
        }

        const att_data = att.data;
        const inclusion_delay = att.inclusion_delay;
        const proposer_index = att.proposer_index;
        const att_slot = att_data.slot;
        const att_voted_target_root = std.mem.eql(u8, att_data.target.root[0..], actual_target_block_root[0..]);
        const att_voted_head_root = att_slot < state_slot and std.mem.eql(u8, att_data.beacon_block_root[0..], &(try getBlockRootAtSlot(state, att_slot)));
        const committee = try epoch_cache.getBeaconCommittee(att_slot, att_data.index);
        // TODO(ssz): implement intersectValues api in https://github.com/ChainSafe/ssz-z/issues/25
        // const participants = att.aggregate_bit.intersectValues(committee);
        var participants = std.ArrayList(ValidatorIndex).init(allocator);
        defer participants.deinit();
        for (committee, 0..) |validator_index, bit_index| {
            if (try att.aggregation_bits.get(bit_index)) {
                try participants.append(validator_index);
            }
        }

        if (epoch == prev_epoch) {
            for (participants.items) |p| {
                if (proposer_indices[p] == validator_count or inclusion_delays[p] > inclusion_delay) {
                    proposer_indices[p] = proposer_index;
                    inclusion_delays[p] = inclusion_delay;
                }
            }
        }

        for (participants.items) |p| {
            flags[p] |= source_flag;
            if (att_voted_target_root) {
                flags[p] |= target_flag;
                if (att_voted_head_root) {
                    flags[p] |= head_flag;
                }
            }
        }
    }
}
