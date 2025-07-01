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
const processPendingConsolidations = @import("./process_pending_consolidations.zig").processPendingConsolidations;
const processEffectiveBalanceUpdates = @import("./process_effective_balance_updates.zig").processEffectiveBalanceUpdates;
const processSlashingsReset = @import("./process_slashings_reset.zig").processSlashingsReset;
const processRandaoMixesReset = @import("./process_randao_mixes_reset.zig").processRandaoMixesReset;
const processHistoricalSummariesUpdate = @import("./process_historical_summaries_update.zig").processHistoricalSummariesUpdate;
const processHistoricalRootsUpdate = @import("./process_historical_roots_update.zig").processHistoricalRootsUpdate;
const processParticipationRecordUpdates = @import("./process_participation_record_updates.zig").processParticipationRecordUpdates;
const processParticipationFlagUpdates = @import("./process_participation_flag_updates.zig").processParticipationFlagUpdates;
const processSyncCommitteeUpdates = @import("./process_sync_committee_updates.zig").processSyncCommitteeUpdates;

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
        try processPendingConsolidations(state, cache);
    }

    // const numUpdate = processEffectiveBalanceUpdates(fork, state, cache);
    _ = try processEffectiveBalanceUpdates(fork, state, cache);

    processSlashingsReset(state, cache);
    processRandaoMixesReset(state, cache);

    if (fork >= ForkSeq.capella) {
        processHistoricalSummariesUpdate(state, cache);
    } else {
        processHistoricalRootsUpdate(state, cache);
    }

    if (fork == ForkSeq.phase0) {
        processParticipationRecordUpdates(state);
    } else {
        processParticipationFlagUpdates(allocator, state);
    }

    processSyncCommitteeUpdates(fork, state);

    // TODO(fulu)
    // processProposerLookahead(fork, state);
}
