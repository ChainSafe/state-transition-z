const std = @import("std");
const testing = std.testing;

pub const computeSigningRoot = @import("./utils/signing_root.zig").computeSigningRoot;
pub const BeaconBlock = @import("./types/beacon_block.zig").BeaconBlock;
pub const BeaconStateAllForks = @import("./types/beacon_state.zig").BeaconStateAllForks;
pub const CachedBeaconStateAllForks = @import("./cache/state_cache.zig").CachedBeaconStateAllForks;

pub const EpochCacheImmutableData = @import("./cache/epoch_cache.zig").EpochCacheImmutableData;
pub const EpochCacheRc = @import("./cache/epoch_cache.zig").EpochCacheRc;
pub const EpochCache = @import("./cache/epoch_cache.zig").EpochCache;

pub const PubkeyIndexMap = @import("./utils/pubkey_index_map.zig").PubkeyIndexMap;
pub const Index2PubkeyCache = @import("./cache/pubkey_cache.zig").Index2PubkeyCache;
pub const syncPubkeys = @import("./cache/pubkey_cache.zig").syncPubkeys;

pub const ReusedEpochTransitionCache = @import("./cache/epoch_transition_cache.zig").ReusedEpochTransitionCache;
pub const EpochTransitionCache = @import("./cache/epoch_transition_cache.zig").EpochTransitionCache;
pub const processJustificationAndFinalization = @import("./epoch/process_justification_and_finalization.zig").processJustificationAndFinalization;
pub const processInactivityUpdates = @import("./epoch/process_inactivity_updates.zig").processInactivityUpdates;
pub const processRegistryUpdates = @import("./epoch/process_registry_updates.zig").processRegistryUpdates;
pub const processSlashings = @import("./epoch/process_slashings.zig").processSlashings;
pub const processRewardsAndPenalties = @import("./epoch/process_rewards_and_penalties.zig").processRewardsAndPenalties;
pub const processEth1DataReset = @import("./epoch/process_eth1_data_reset.zig").processEth1DataReset;
pub const processPendingDeposits = @import("./epoch/process_pending_deposits.zig").processPendingDeposits;
pub const processPendingConsolidations = @import("./epoch/process_pending_consolidations.zig").processPendingConsolidations;
// pub const processEffectiveBalanceUpdates = @import("./epoch/process_effective_balance_updates.zig").processEffectiveBalanceUpdates;
// pub const processSlashingsReset = @import("./epoch/process_slashings_reset.zig").processSlashingsReset;
// pub const processRandaoMixesReset = @import("./epoch/process_randao_mixes_reset.zig").processRandaoMixesReset;
// pub const processHistoricalSummariesUpdate = @import("./epoch/process_historical_summaries_update.zig").processHistoricalSummariesUpdate;
// pub const processHistoricalRootsUpdate = @import("./epoch/process_historical_roots_update.zig").processHistoricalRootsUpdate;
// pub const processParticipationRecordUpdates = @import("./epoch/process_participation_record_updates.zig").processParticipationRecordUpdates;
// pub const processParticipationFlagUpdates = @import("./epoch/process_participation_flag_updates.zig").processParticipationFlagUpdates;
// pub const processSyncCommitteeUpdates = @import("./epoch/process_sync_committee_updates.zig").processSyncCommitteeUpdates;

pub const bls = @import("utils/bls.zig");
const seed = @import("./utils/seed.zig");
const EpochShuffling = @import("./utils/epoch_shuffling.zig");

test {
    testing.refAllDecls(@This());
    testing.refAllDecls(seed);
    testing.refAllDecls(EpochShuffling);
}
