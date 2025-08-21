const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const params = @import("params");
const GENESIS_EPOCH = params.GENESIS_EPOCH;
const computeEpochAtSlot = @import("../utils/epoch.zig").computeEpochAtSlot;
const ssz = @import("consensus_types");
const getBlockRoot = @import("../utils/block_root.zig").getBlockRoot;

/// Update justified and finalized checkpoints depending on network participation.
///
/// PERF: Very low (constant) cost. Persist small objects to the tree.
pub fn processJustificationAndFinalization(cached_state: *CachedBeaconStateAllForks, cache: *const EpochTransitionCache) !void {
    // Initial FFG checkpoint values have a `0x00` stub for `root`.
    // Skip FFG updates in the first two epochs to avoid corner cases that might result in modifying this stub.
    if (cache.current_epoch <= GENESIS_EPOCH + 1) {
        return;
    }
    try weighJustificationAndFinalization(cached_state, cache.total_active_stake_by_increment, cache.prev_epoch_unslashed_stake_target_by_increment, cache.curr_epoch_unslashed_target_stake_by_increment);
}

pub fn weighJustificationAndFinalization(cached_state: *CachedBeaconStateAllForks, total_active_balance: u64, previous_epoch_target_balance: u64, current_epoch_target_balance: u64) !void {
    const state = cached_state.state;
    const current_epoch = computeEpochAtSlot(state.getSlot());
    const previous_epoch = current_epoch - 1;

    const old_previous_justified_checkpoint = state.getPreviousJustifiedCheckpoint();
    const old_current_justified_checkpoint = state.getCurrentJustifiedCheckpoint();

    // Process justifications
    state.setPreviousJustifiedCheckpoint(state.getCurrentJustifiedCheckpoint());
    const justification_bits = state.getJustificationBits();
    var bits = [_]bool{false} ** ssz.phase0.JustificationBits.length;
    for (0..bits.len) |i| {
        bits[i] = try justification_bits.get(i);
    }

    // Rotate bits
    var i: usize = bits.len - 1;
    while (i > 0) : (i -= 1) {
        bits[i] = bits[i - 1];
    }
    bits[0] = false;

    if (previous_epoch_target_balance * 3 > total_active_balance * 2) {
        state.setCurrentJustifiedCheckpoint(&.{
            .epoch = previous_epoch,
            .root = try getBlockRoot(state, previous_epoch),
        });
        bits[1] = true;
    }

    if (current_epoch_target_balance * 3 > total_active_balance * 2) {
        state.setCurrentJustifiedCheckpoint(&.{
            .epoch = current_epoch,
            .root = try getBlockRoot(state, current_epoch),
        });
        bits[0] = true;
    }

    state.setJustificationBits(try ssz.phase0.JustificationBits.Type.fromBoolArray(bits));

    // TODO: Consider rendering bits as array of boolean for faster repeated access here

    // Process finalizations
    // The 2nd/3rd/4th most recent epochs are all justified, the 2nd using the 4th as source
    if (bits[1] and bits[2] and bits[3] and old_previous_justified_checkpoint.epoch + 3 == current_epoch) {
        state.setFinalizedCheckpoint(old_previous_justified_checkpoint);
    }
    // The 2nd/3rd most recent epochs are both justified, the 2nd using the 3rd as source
    if (bits[1] and bits[2] and old_previous_justified_checkpoint.epoch + 2 == current_epoch) {
        state.setFinalizedCheckpoint(old_previous_justified_checkpoint);
    }
    // The 1st/2nd/3rd most recent epochs are all justified, the 1st using the 3rd as source
    if (bits[0] and bits[1] and bits[2] and old_current_justified_checkpoint.epoch + 2 == current_epoch) {
        state.setFinalizedCheckpoint(old_current_justified_checkpoint);
    }
    // The 1st/2nd most recent epochs are both justified, the 1st using the 2nd as source
    if (bits[0] and bits[1] and old_current_justified_checkpoint.epoch + 1 == current_epoch) {
        state.setFinalizedCheckpoint(old_current_justified_checkpoint);
    }
}
