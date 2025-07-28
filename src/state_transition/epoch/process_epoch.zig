const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ForkSeq = @import("params").ForkSeq;
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
pub fn process_epoch(allocator: std.mem.Allocator, cached_state: *CachedBeaconStateAllForks, cache: *const EpochTransitionCache) !void {
    const state = cached_state.state;
    try processJustificationAndFinalization(cached_state, cache);

    if (state.isPostAltair()) {
        try processInactivityUpdates(cached_state, cache);
    }

    try processRegistryUpdates(cached_state, cache);

    try processSlashings(allocator, cached_state, cache);

    try processRewardsAndPenalties(cached_state, cache);

    processEth1DataReset(cached_state, cache);

    if (state.isPostElectra()) {
        try processPendingDeposits(cached_state, cache);
        try processPendingConsolidations(cached_state, cache);
    }

    // const numUpdate = processEffectiveBalanceUpdates(fork, state, cache);
    _ = try processEffectiveBalanceUpdates(cached_state, cache);

    processSlashingsReset(cached_state, cache);
    processRandaoMixesReset(cached_state, cache);

    if (state.isPostCapella()) {
        try processHistoricalSummariesUpdate(cached_state, cache);
    } else {
        try processHistoricalRootsUpdate(cached_state, cache);
    }

    if (state.isPhase0()) {
        processParticipationRecordUpdates(cached_state);
    } else {
        processParticipationFlagUpdates(allocator, cached_state);
    }

    try processSyncCommitteeUpdates(allocator, cached_state);

    // TODO(fulu)
    // processProposerLookahead(fork, state);
}
