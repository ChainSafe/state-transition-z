const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("../config.zig").ForkSeq;
const EpochTransitionCache = @import("../cache/epoch_transition_cache.zig").EpochTransitionCache;
const processJustificationAndFinalization = @import("./process_justification_and_finalization.zig").processJustificationAndFinalization;
const processInactivityUpdates = @import("./process_inactivity_updates.zig").processInactivityUpdates;
const processRegistryUpdates = @import("./process_registry_updates.zig").processRegistryUpdates;
const processSlashings = @import("./process_slashings.zig").processSlashings;
const processRewardsAndPenalties = @import("./process_rewards_and_penalties.zig").processRewardsAndPenalties;
const processEth1DataReset = @import("./process_eth1_data_reset.zig").processEth1DataReset;
const processPendingDeposits = @import("./process_pending_deposits.zig").processPendingDeposits;

// TODO: add metrics
pub fn process_epoch(allocator: std.mem.Allocator, fork: ForkSeq, state: *CachedBeaconStateAllForks, cache: EpochTransitionCache) !void {
    processJustificationAndFinalization(state, cache);

    if (fork >= ForkSeq.altair) {
        processInactivityUpdates(state, cache);
    }

    processRegistryUpdates(fork, state, cache);

    processSlashings(allocator, state, cache);

    processRewardsAndPenalties(state, cache);

    processEth1DataReset(state, cache);

    if (fork >= ForkSeq.electra) {
        try processPendingDeposits(state, cache);
        // processPendingConsolidations(stateElectra, cache);
    }

    // const numUpdate = processEffectiveBalanceUpdates(fork, state, cache);

    // processSlashingsReset(state, cache);
    // processRandaoMixesReset(state, cache);

    // if (fork >= ForkSeq.capella) {
    //     processHistoricalSummariesUpdate(state, cache);
    // } else {
    //     processHistoricalRootsUpdate(state, cache);
    // }

    // if (fork == ForkSeq.phase0) {
    //     processParticipationRecordUpdates(state);
    // } else {
    //     processParticipationFlagUpdates(state);
    // }

    // processSyncCommitteeUpdates(fork, state);

    // TODO
    // processProposerLookahead(fork, state);
}
