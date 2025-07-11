const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const types = @import("../types.zig");
const Epoch = types.Epoch;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const params = @import("params");
const GENESIS_EPOCH = params.GENESIS_EPOCH;
const isInInactivityLeak = @import("../utils/finality.zig").isInInactivityLeak;
const attester_status_utils = @import("../utils/attester_status.zig");
const hasMarkers = attester_status_utils.hasMarkers;

pub fn processInactivityUpdates(cached_state: CachedBeaconStateAllForks, cache: EpochTransitionCache) !void {
    if (cached_state.epoch_cache.epoch == GENESIS_EPOCH) {
        return;
    }

    const state = cached_state.state;
    const config = cached_state.config.chain;
    const INACTIVITY_SCORE_BIAS = config.INACTIVITY_SCORE_BIAS;
    const INACTIVITY_SCORE_RECOVERY_RATE = config.INACTIVITY_SCORE_RECOVERY_RATE;
    const flags = cache.flags;
    const in_activity_leak = isInInactivityLeak(cached_state);

    // this avoids importing FLAG_ELIGIBLE_ATTESTER inside the for loop, check the compiled code
    const FLAG_PREV_TARGET_ATTESTER_UNSLASHED = attester_status_utils.FLAG_PREV_TARGET_ATTESTER_UNSLASHED;
    const FLAG_ELIGIBLE_ATTESTER = attester_status_utils.FLAG_ELIGIBLE_ATTESTER;

    // for TreeView, we may need a reused inactivityScoresArr

    for (0..flags.items.len) |i| {
        const flag = flags.items[i];
        if (hasMarkers(flag, FLAG_ELIGIBLE_ATTESTER)) {
            var inactivity_score = state.getInactivityScore(i);

            const prev_inactivity_score = inactivity_score;
            if (hasMarkers(flag, FLAG_PREV_TARGET_ATTESTER_UNSLASHED)) {
                inactivity_score -= @min(1, inactivity_score);
            } else {
                inactivity_score += INACTIVITY_SCORE_BIAS;
            }
            if (!in_activity_leak) {
                inactivity_score -= @min(INACTIVITY_SCORE_RECOVERY_RATE, inactivity_score);
            }
            if (inactivity_score != prev_inactivity_score) {
                state.setInactivityScore(i, inactivity_score);
            }
        }
    }
}
