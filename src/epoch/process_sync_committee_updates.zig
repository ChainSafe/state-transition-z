const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("../config.zig").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const ValidatorIndex = @import("../type.zig").ValidatorIndex;
const BLSPubkey = @import("../type.zig").BLSPubkey;
const getNextSyncCommitteeIndices = @import("../utils/sync_committee.zig").getNextSyncCommitteeIndices;
const aggregateSerializedPublicKeys = @import("../utils/bls.zig").aggregateSerializedPublicKeys;

pub fn processSyncCommitteeUpdates(allocator: Allocator, fork_seq: ForkSeq, cached_state: *CachedBeaconStateAllForks) !void {
    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;
    const next_epoch = epoch_cache.epoch + 1;
    if (next_epoch % preset.EPOCHS_PER_SYNC_COMMITTEE_PERIOD == 0) {
        // borrow from EpochShuffling so no need to deinit it
        const active_validator_indices = epoch_cache.next_shuffling.get().active_indices.items;
        const effective_balance_increments = epoch_cache.effective_balance_increment.get();
        const next_sync_committee_indices = try allocator.alloc(ValidatorIndex, preset.SYNC_COMMITTEE_SIZE);
        try getNextSyncCommitteeIndices(allocator, fork_seq, state, active_validator_indices, effective_balance_increments, allocator.alloc(u32, preset.SYNC_COMMITTEE_SIZE), next_sync_committee_indices);
        const validators = state.getValidators();

        // Using the index2pubkey cache is slower because it needs the serialized pubkey.
        var next_sync_committee_pubkeys: [preset.SYNC_COMMITTEE_SIZE]BLSPubkey = undefined;
        for (next_sync_committee_indices, 0..next_sync_committee_indices.len) |index, i| {
            next_sync_committee_pubkeys[i] = validators.items[index].pubkey;
        }

        // Rotate syncCommittee in state
        state.setCurrentSyncCommittee(state.getNextSyncCommittee());
        state.setNextSyncCommittee(.{
            .pubkeys = next_sync_committee_pubkeys,
            // TODO(blst): may need to modify AggregatePublicKey.aggregateSerialized to accept this param
            .aggregatePubkey = aggregateSerializedPublicKeys(&next_sync_committee_pubkeys).toBytes(),
        });

        // Rotate syncCommittee cache
        epoch_cache.rotateSyncCommitteeIndexed(next_sync_committee_indices);
    }
}
