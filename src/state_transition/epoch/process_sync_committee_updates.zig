const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("params").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const ValidatorIndex = @import("../type.zig").ValidatorIndex;
const BLSPubkey = @import("../type.zig").BLSPubkey;
const getNextSyncCommitteeIndices = @import("../utils/sync_committee.zig").getNextSyncCommitteeIndices;
const aggregateSerializedPublicKeys = @import("../utils/bls.zig").aggregateSerializedPublicKeys;

pub fn processSyncCommitteeUpdates(allocator: Allocator, cached_state: *CachedBeaconStateAllForks) !void {
    const state = cached_state.state;
    const epoch_cache = cached_state.getEpochCache();
    const next_epoch = epoch_cache.epoch + 1;
    if (next_epoch % preset.EPOCHS_PER_SYNC_COMMITTEE_PERIOD == 0) {
        const active_validator_indices = epoch_cache.getNextEpochShuffling().active_indices;
        const effective_balance_increments = epoch_cache.getEffectiveBalanceIncrements();
        var next_sync_committee_indices: [preset.SYNC_COMMITTEE_SIZE]ValidatorIndex = undefined;
        try getNextSyncCommitteeIndices(allocator, state, active_validator_indices, effective_balance_increments, &next_sync_committee_indices);
        const validators = state.validators();

        // Using the index2pubkey cache is slower because it needs the serialized pubkey.
        var next_sync_committee_pubkeys: [preset.SYNC_COMMITTEE_SIZE]BLSPubkey = undefined;
        var next_sync_committee_pubkeys_slices: [preset.SYNC_COMMITTEE_SIZE][]const u8 = undefined;
        for (next_sync_committee_indices, 0..next_sync_committee_indices.len) |index, i| {
            next_sync_committee_pubkeys[i] = validators.items[index].pubkey;
            next_sync_committee_pubkeys_slices[i] = &next_sync_committee_pubkeys[i];
        }

        const current_sync_committee = state.currentSyncCommittee();
        const next_sync_committee = state.nextSyncCommittee();
        current_sync_committee.* = next_sync_committee.*;
        // Rotate syncCommittee in state
        next_sync_committee.* = .{
            .pubkeys = next_sync_committee_pubkeys,
            // TODO(blst): may need to modify AggregatePublicKey.aggregateSerialized to accept this param
            // TODO(blst): is this correct to convert AggregatedPubkey to PublicKey first then toBytes()? there is no toBytes in AggregatedPubkey for now
            .aggregate_pubkey = (try aggregateSerializedPublicKeys(&next_sync_committee_pubkeys_slices, false)).toPublicKey().toBytes(),
        };

        // Rotate syncCommittee cache
        // next_sync_committee_indices ownership is transferred to epoch_cache
        try epoch_cache.rotateSyncCommitteeIndexed(allocator, &next_sync_committee_indices);
    }
}
