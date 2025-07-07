const std = @import("std");
const expect = std.testing.expect;
const ssz = @import("consensus_types");
const BeaconStatePhase0 = ssz.phase0.BeaconState.Type;
const BeaconStateAltair = ssz.altair.BeaconState.Type;
const BeaconStateBellatrix = ssz.bellatrix.BeaconState.Type;
const BeaconStateCapella = ssz.capella.BeaconState.Type;
const BeaconStateDeneb = ssz.deneb.BeaconState.Type;
const BeaconStateElectra = ssz.electra.BeaconState.Type;
const ExecutionPayloadHeader = @import("./execution_payload.zig").ExecutionPayloadHeader;
const Root = ssz.primitive.Root.Type;
const Fork = ssz.phase0.Fork.Type;
const BeaconBlockHeader = ssz.phase0.BeaconBlockHeader.Type;
const Eth1Data = ssz.phase0.Eth1Data.Type;
const Eth1DataVotes = ssz.phase0.Eth1DataVotes.Type;
const Validator = ssz.phase0.Validator.Type;
const Validators = ssz.phase0.Validators.Type;
const PendingAttestation = ssz.phase0.PendingAttestation.Type;
const JustificationBits = ssz.phase0.JustificationBits.Type;
const Checkpoint = ssz.phase0.Checkpoint.Type;
const SyncCommittee = ssz.altair.SyncCommittee.Type;
const HistoricalSummary = ssz.capella.HistoricalSummary;
const PendingDeposit = ssz.electra.PendingDeposit.Type;
const PendingPartialWithdrawal = ssz.electra.PendingPartialWithdrawal.Type;
const PendingConsolidation = ssz.electra.PendingConsolidation.Type;
const Bytes32 = ssz.primitive.Bytes32.Type;
const Gwei = ssz.primitive.Gwei.Type;
const Epoch = ssz.primitive.Epoch.Type;

/// wrapper for all BeaconState types across forks so that we don't have to do switch/case for all methods
/// right now this works with regular types
/// TODO: migrate this to TreeView and implement the same set of methods here because TreeView objects does not have a great Devex APIs
pub const BeaconStateAllForks = union(enum) {
    phase0: *BeaconStatePhase0,
    altair: *BeaconStateAltair,
    bellatrix: *BeaconStateBellatrix,
    capella: *BeaconStateCapella,
    deneb: *BeaconStateDeneb,
    electra: *BeaconStateElectra,

    pub fn hashTreeRoot(self: *const BeaconStateAllForks, allocator: std.mem.Allocator, out: *[32]u8) !void {
        return switch (self.*) {
            inline .phase0 => |state| try ssz.phase0.BeaconState.hashTreeRoot(allocator, state, out),
            inline .altair => |state| try ssz.altair.BeaconState.hashTreeRoot(allocator, state, out),
            inline .bellatrix => |state| try ssz.bellatrix.BeaconState.hashTreeRoot(allocator, state, out),
            inline .capella => |state| try ssz.capella.BeaconState.hashTreeRoot(allocator, state, out),
            inline .deneb => |state| try ssz.deneb.BeaconState.hashTreeRoot(allocator, state, out),
            inline .electra => |state| try ssz.electra.BeaconState.hashTreeRoot(allocator, state, out),
        };
    }

    pub fn isPostAltair(self: *const BeaconStateAllForks) bool {
        return switch (self.*) {
            inline .phase0 => false,
            inline .altair, .bellatrix, .capella, .deneb, .electra => true,
        };
    }

    pub fn isBellatrix(self: *const BeaconStateAllForks) bool {
        return switch (self.*) {
            .bellatrix => true,
            else => false,
        };
    }

    pub fn isPostBellatrix(self: *const BeaconStateAllForks) bool {
        return switch (self.*) {
            inline .phase0, .altair => false,
            inline .bellatrix, .capella, .deneb, .electra => true,
        };
    }

    pub fn isPostCapella(self: *const BeaconStateAllForks) bool {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix => false,
            inline .capella, .deneb, .electra => true,
        };
    }

    pub fn isPostDeneb(self: *const BeaconStateAllForks) bool {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella => false,
            inline .deneb, .electra => true,
        };
    }

    pub fn isPostElectra(self: *const BeaconStateAllForks) bool {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb => false,
            inline .electra => true,
        };
    }

    pub fn getGenesisTime(self: *const BeaconStateAllForks) u64 {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.genesis_time,
        };
    }

    pub fn setGenesisTime(self: *BeaconStateAllForks, genesis_time: u64) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.genesis_time = genesis_time,
        }
    }

    pub fn getGenesisValidatorsRoot(self: *const BeaconStateAllForks) Root {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.genesis_validators_root,
        };
    }

    pub fn setGenesisValidatorRoot(self: *BeaconStateAllForks, root: Root) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.genesis_validators_root = root,
        }
    }

    pub fn getSlot(self: *const BeaconStateAllForks) u64 {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.slot,
        };
    }

    pub fn setSlot(self: *BeaconStateAllForks, slot: u64) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.slot = slot,
        }
    }

    pub fn getFork(self: *const BeaconStateAllForks) Fork {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.fork,
        };
    }

    pub fn setFork(self: *BeaconStateAllForks, fork: Fork) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.fork = fork,
        }
    }

    pub fn getLatestBlockHeader(self: *const BeaconStateAllForks) *BeaconBlockHeader {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| &state.latest_block_header,
        };
    }

    pub fn setLatestBlockHeader(self: *BeaconStateAllForks, header: *BeaconBlockHeader) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.latest_block_header = *header,
        }
    }

    pub fn getBlockRoot(self: *const BeaconStateAllForks, index: usize) Root {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.block_roots.items[index],
        };
    }

    pub fn getBlockRoots(self: *const BeaconStateAllForks) []const Root {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.block_roots.items,
        };
    }

    pub fn setBlockRoot(self: *BeaconStateAllForks, index: usize, root: Root) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.block_roots.items[index] = root,
        }
    }

    pub fn getStateRoot(self: *const BeaconStateAllForks, index: usize) Root {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.state_roots.items[index],
        };
    }

    pub fn getStateRoots(self: *const BeaconStateAllForks) []const Root {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.state_roots.items,
        };
    }

    pub fn setStateRoot(self: *BeaconStateAllForks, index: usize, root: Root) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.state_roots.items[index] = root,
        }
    }

    pub fn getHistoricalRoot(self: *const BeaconStateAllForks, index: usize) Root {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.historical_roots.items[index],
        };
    }

    pub fn setHistoricalRoot(self: *BeaconStateAllForks, index: usize, root: Root) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.historical_roots.items[index] = root,
        }
    }

    pub fn addHistoricalRoot(self: *BeaconStateAllForks, root: Root) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.historical_roots.append(root),
        }
    }

    pub fn getEth1Data(self: *const BeaconStateAllForks) *Eth1Data {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| &state.eth1_data,
        };
    }

    pub fn setEth1Data(self: *BeaconStateAllForks, eth1_data: *const Eth1Data) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.eth1_data = *eth1_data,
        }
    }

    pub fn getEth1DataVotes(self: *const BeaconStateAllForks) *const Eth1DataVotes {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| &state.eth1_data_votes,
        };
    }

    // TODO: why eth1_data_votes as pointer does not work?
    pub fn setEth1DataVotes(self: *BeaconStateAllForks, eth1_data_votes: Eth1DataVotes) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.eth1_data_votes = eth1_data_votes,
        }
    }

    pub fn getEth1DepositIndex(self: *const BeaconStateAllForks) u64 {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.eth1_deposit_index,
        };
    }

    pub fn setEth1DepositIndex(self: *BeaconStateAllForks, index: u64) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.eth1_deposit_index = index,
        }
    }

    pub fn getValidator(self: *const BeaconStateAllForks, index: usize) *Validator {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| &state.validators.items[index],
        };
    }

    pub fn getValidators(self: *const BeaconStateAllForks) Validators {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.validators,
        };
    }

    pub fn setValidator(self: *BeaconStateAllForks, index: usize, validator: *const Validator) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.validators.items[index] = *validator,
        }
    }

    pub fn appendValidator(self: *BeaconStateAllForks, validator: *const Validator) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.validators.append(*validator),
        }
    }

    pub fn getBalance(self: *const BeaconStateAllForks, index: usize) u64 {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.balances.items[index],
        };
    }

    pub fn appendBalance(self: *BeaconStateAllForks, amount: u64) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.balances.append(amount),
        }
    }

    pub fn setBalance(self: *BeaconStateAllForks, index: usize, balance: u64) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.balances.items[index] = balance,
        }
    }

    pub fn getBalances(self: *const BeaconStateAllForks) []const u64 {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.balances.items,
        };
    }

    pub fn getValidatorsCount(self: *const BeaconStateAllForks) usize {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.validators.len,
        };
    }

    pub fn getRanDaoMix(self: *const BeaconStateAllForks, index: usize) Bytes32 {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.randao_mixes.items[index],
        };
    }

    pub fn setRandaoMix(self: *BeaconStateAllForks, index: usize, mix: Bytes32) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.randao_mixes.items[index] = mix,
        }
    }

    pub fn getSlashing(self: *const BeaconStateAllForks, index: usize) u64 {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.slashings.items[index],
        };
    }

    pub fn getSlashingCount(self: *const BeaconStateAllForks) usize {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.slashings.len,
        };
    }

    pub fn setSlashing(self: *BeaconStateAllForks, index: usize, slashing: u64) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.slashings.items[index] = slashing,
        }
    }

    /// only for phase0
    pub fn getPreviousEpochPendingAttestation(self: *const BeaconStateAllForks, index: usize) *const PendingAttestation {
        return switch (self.*) {
            .phase0 => |state| &state.previous_epoch_attestations[index],
            else => @panic("previous_epoch_pending_attestations is not available post phase0"),
        };
    }

    /// only for phase0
    pub fn getPreviousEpochPendingAttestations(self: *const BeaconStateAllForks) []const PendingAttestation {
        return switch (self.*) {
            .phase0 => |state| state.previous_epoch_attestations,
            else => @panic("previous_epoch_pending_attestations is not available post phase0"),
        };
    }

    /// only for phase0
    pub fn setPreviousEpochPendingAttestation(self: *BeaconStateAllForks, index: usize, attestation: *const PendingAttestation) void {
        switch (self.*) {
            .phase0 => |state| state.previous_epoch_attestations[index] = *attestation,
            else => @panic("previous_epoch_pending_attestations is not available post phase0"),
        }
    }

    pub fn setPreviousEpochPendingAttestations(self: *BeaconStateAllForks, attestations: std.ArrayListUnmanaged(PendingAttestation)) void {
        switch (self.*) {
            .phase0 => |state| state.previous_epoch_attestations = attestations,
            else => @panic("previous_epoch_pending_attestations is not available post phase0"),
        }
    }

    // only for phase0
    pub fn getCurrentEpochPendingAttestations(self: *const BeaconStateAllForks) []const PendingAttestation {
        return switch (self.*) {
            .phase0 => |state| state.current_epoch_attestations,
            else => @panic("current_epoch_pending_attestations is not available post phase0"),
        };
    }

    pub fn setCurrentEpochPendingAttestations(self: *BeaconStateAllForks, attestations: std.ArrayListUnmanaged(PendingAttestation)) void {
        switch (self.*) {
            .phase0 => |state| state.current_epoch_attestations = attestations,
            else => @panic("current_epoch_pending_attestations is not available post phase0"),
        }
    }

    /// from altair, epoch pariticipation is just a byte
    pub fn getPreviousEpochParticipation(self: *const BeaconStateAllForks, index: usize) u8 {
        return switch (self.*) {
            .phase0 => @panic("previous_epoch_participation is not available in phase0"),
            else => |state| state.previous_epoch_participation.items[index],
        };
    }

    // from altair
    pub fn getPreviousEpochParticipations(self: *const BeaconStateAllForks) std.ArrayListUnmanaged(u8) {
        return switch (self.*) {
            .phase0 => @panic("previous_epoch_participation is not available in phase0"),
            else => |state| state.previous_epoch_participation.items,
        };
    }

    pub fn addPreviousEpochParticipation(self: *BeaconStateAllForks, participation: u8) void {
        switch (self.*) {
            .phase0 => @panic("previous_epoch_participation is not available in phase0"),
            else => |state| state.previous_epoch_participation.append(participation),
        }
    }

    /// from altair, epoch participation is just a byte
    pub fn setPreviousEpochParticipation(self: *BeaconStateAllForks, index: usize, participation: u8) void {
        switch (self.*) {
            .phase0 => @panic("previous_epoch_participation is not available in phase0"),
            else => |state| state.previous_epoch_participation.items[index] = participation,
        }
    }

    pub fn getCurrentEpochParticipations(self: *const BeaconStateAllForks) []const u8 {
        return switch (self.*) {
            .phase0 => @panic("current_epoch_participation is not available in phase0"),
            else => |state| state.current_epoch_participation.items,
        };
    }

    pub fn getCurrentEpochParticipation(self: *const BeaconStateAllForks, index: usize) u8 {
        return switch (self.*) {
            .phase0 => @panic("current_epoch_participation is not available in phase0"),
            else => |state| state.current_epoch_participation.items[index],
        };
    }

    pub fn setPreviousEpochParticipations(self: *BeaconStateAllForks, participations: std.ArrayListUnmanaged(u8)) void {
        switch (self.*) {
            .phase0 => @panic("current_epoch_participation is not available in phase0"),
            else => |state| state.previous_epoch_participation = participations,
        }
    }

    pub fn addCurrentEpochParticipation(self: *BeaconStateAllForks, participation: u8) void {
        switch (self.*) {
            .phase0 => @panic("current_epoch_participation is not available in phase0"),
            else => |state| state.current_epoch_participation.append(participation),
        }
    }

    pub fn setCurrentEpochParticipations(self: *BeaconStateAllForks, participations: std.ArrayListUnmanaged(u8)) void {
        switch (self.*) {
            .phase0 => @panic("current_epoch_participation is not available in phase0"),
            else => |state| state.current_epoch_participation = participations,
        }
    }

    pub fn getJustificationBits(self: *const BeaconStateAllForks) JustificationBits {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.justification_bits,
        };
    }

    pub fn setJustificationBits(self: *BeaconStateAllForks, bits: JustificationBits) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.justification_bits = bits,
        }
    }

    pub fn getPreviousJustifiedCheckpoint(self: *const BeaconStateAllForks) *const Checkpoint {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| &state.previous_justified_checkpoint,
        };
    }

    pub fn setPreviousJustifiedCheckpoint(self: *BeaconStateAllForks, checkpoint: *const Checkpoint) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.previous_justified_checkpoint = *checkpoint,
        }
    }

    pub fn getCurrentJustifiedCheckpoint(self: *const BeaconStateAllForks) *const Checkpoint {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| &state.current_justified_checkpoint,
        };
    }

    pub fn setCurrentJustifiedCheckpoint(self: *BeaconStateAllForks, checkpoint: *const Checkpoint) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.current_justified_checkpoint = *checkpoint,
        }
    }

    pub fn getFinalizedCheckpoint(self: *const BeaconStateAllForks) *const Checkpoint {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| &state.finalized_checkpoint,
        };
    }

    pub fn setFinalizedCheckpoint(self: *BeaconStateAllForks, checkpoint: *const Checkpoint) void {
        switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |state| state.finalized_checkpoint = *checkpoint,
        }
    }

    pub fn getInactivityScore(self: *const BeaconStateAllForks, index: usize) u64 {
        return switch (self.*) {
            .phase0 => @panic("inactivity_scores is not available in phase0"),
            else => |state| state.inactivity_scores.items[index],
        };
    }

    pub fn setInactivityScore(self: *BeaconStateAllForks, index: usize, score: u64) void {
        switch (self.*) {
            .phase0 => @panic("inactivity_scores is not available in phase0"),
            else => |state| state.inactivity_scores.items[index] = score,
        }
    }

    pub fn addInactivityScore(self: *BeaconStateAllForks, score: u64) void {
        switch (self.*) {
            .phase0 => @panic("inactivity_scores is not available in phase0"),
            else => |state| state.inactivity_scores.append(score),
        }
    }

    pub fn getCurrentSyncCommittee(self: *const BeaconStateAllForks) *const SyncCommittee {
        return switch (self.*) {
            .phase0 => @panic("current_sync_committee is not available in phase0"),
            else => |state| &state.current_sync_committee,
        };
    }

    pub fn setCurrentSyncCommittee(self: *BeaconStateAllForks, sync_committee: *const SyncCommittee) void {
        switch (self.*) {
            .phase0 => @panic("current_sync_committee is not available in phase0"),
            else => |state| state.current_sync_committee = *sync_committee,
        }
    }

    pub fn getNextSyncCommittee(self: *const BeaconStateAllForks) *const SyncCommittee {
        return switch (self.*) {
            .phase0 => @panic("next_sync_committee is not available in phase0"),
            else => |state| &state.next_sync_committee,
        };
    }

    pub fn setNextSyncCommittee(self: *BeaconStateAllForks, sync_committee: *const SyncCommittee) void {
        switch (self.*) {
            .phase0 => @panic("next_sync_committee is not available in phase0"),
            else => |state| state.next_sync_committee = *sync_committee,
        }
    }

    pub fn getLatestExecutionPayloadHeader(self: *const BeaconStateAllForks) *const ExecutionPayloadHeader {
        return switch (self.*) {
            .phase0 => @panic("latest_execution_payload_header is not available in phase0"),
            .altair => @panic("latest_execution_payload_header is not available in altair"),
            .bellatrix => |state| &.{ .bellatrix = state.latest_execution_payload_header },
            .capella => |state| &.{ .capella = state.latest_execution_payload_header },
            .deneb, .electra => |state| &.{ .deneb = state.latest_execution_payload_header },
        };
    }

    pub fn setLatestExecutionPayloadHeader(self: *BeaconStateAllForks, header: *const ExecutionPayloadHeader) void {
        switch (self.*) {
            .phase0 => @panic("latest_execution_payload_header is not available in phase0"),
            .altair => @panic("latest_execution_payload_header is not available in altair"),
            .bellatrix => |state| state.latest_execution_payload_header = header.*.bellatrix,
            .capella => |state| state.latest_execution_payload_header = header.*.capella,
            .deneb, .electra => |state| state.latest_execution_payload_header = header.*.deneb,
        }
    }

    pub fn getNextWithdrawalIndex(self: *const BeaconStateAllForks) u64 {
        return switch (self.*) {
            .phase0 => @panic("next_withdrawal_index is not available in phase0"),
            .altair => @panic("next_withdrawal_index is not available in altair"),
            .bellatrix => @panic("next_withdrawal_index is not available in bellatrix"),
            else => |state| state.next_withdrawal_index,
        };
    }

    pub fn setNextWithdrawalIndex(self: *BeaconStateAllForks, index: u64) void {
        switch (self.*) {
            .phase0 => @panic("next_withdrawal_index is not available in phase0"),
            .altair => @panic("next_withdrawal_index is not available in altair"),
            .bellatrix => @panic("next_withdrawal_index is not available in bellatrix"),
            else => |state| state.next_withdrawal_index = index,
        }
    }

    pub fn getNextWithdrawalValidatorIndex(self: *const BeaconStateAllForks) u64 {
        return switch (self.*) {
            .phase0 => @panic("next_withdrawal_validator_index is not available in phase0"),
            .altair => @panic("next_withdrawal_validator_index is not available in altair"),
            .bellatrix => @panic("next_withdrawal_validator_index is not available in bellatrix"),
            else => |state| state.next_withdrawal_validator_index,
        };
    }

    pub fn setNextWithdrawalValidatorIndex(self: *BeaconStateAllForks, index: u64) void {
        switch (self.*) {
            .phase0 => @panic("next_withdrawal_validator_index is not available in phase0"),
            .altair => @panic("next_withdrawal_validator_index is not available in altair"),
            .bellatrix => @panic("next_withdrawal_validator_index is not available in bellatrix"),
            else => |state| state.next_withdrawal_validator_index = index,
        }
    }

    pub fn getHistoricalSummary(self: *const BeaconStateAllForks, index: usize) *const HistoricalSummary {
        return switch (self.*) {
            .phase0 => @panic("historical_summary is not available in phase0"),
            .altair => @panic("historical_summary is not available in altair"),
            .bellatrix => @panic("historical_summary is not available in bellatrix"),
            else => |state| &state.historical_summaries.items[index],
        };
    }

    pub fn setHistoricalSummary(self: *BeaconStateAllForks, index: usize, summary: *const HistoricalSummary) void {
        switch (self.*) {
            .phase0 => @panic("historical_summary is not available in phase0"),
            .altair => @panic("historical_summary is not available in altair"),
            .bellatrix => @panic("historical_summary is not available in bellatrix"),
            else => |state| state.historical_summaries.items[index] = *summary,
        }
    }

    pub fn addHistoricalSummary(self: *BeaconStateAllForks, summary: *const HistoricalSummary) void {
        switch (self.*) {
            .phase0 => @panic("historical_summary is not available in phase0"),
            .altair => @panic("historical_summary is not available in altair"),
            .bellatrix => @panic("historical_summary is not available in bellatrix"),
            else => |state| state.historical_summaries.append(*summary),
        }
    }

    pub fn getDepositRequestsStartIndex(self: *const BeaconStateAllForks) u64 {
        return switch (self.*) {
            .phase0 => @panic("deposit_requests_start_index is not available in phase0"),
            .altair => @panic("deposit_requests_start_index is not available in altair"),
            .bellatrix => @panic("deposit_requests_start_index is not available in bellatrix"),
            .capella => @panic("deposit_requests_start_index is not available in capella"),
            .deneb => @panic("deposit_requests_start_index is not available in deneb"),
            .electra => |state| state.deposit_requests_start_index,
        };
    }

    pub fn setDepositRequestsStartIndex(self: *BeaconStateAllForks, index: u64) void {
        switch (self.*) {
            .phase0 => @panic("deposit_requests_start_index is not available in phase0"),
            .altair => @panic("deposit_requests_start_index is not available in altair"),
            .bellatrix => @panic("deposit_requests_start_index is not available in bellatrix"),
            .capella => @panic("deposit_requests_start_index is not available in capella"),
            .deneb => @panic("deposit_requests_start_index is not available in deneb"),
            .electra => |state| state.deposit_requests_start_index = index,
        }
    }

    pub fn getDepositBalanceToConsume(self: *const BeaconStateAllForks) Gwei {
        return switch (self.*) {
            .phase0 => @panic("deposit_balance_to_consume is not available in phase0"),
            .altair => @panic("deposit_balance_to_consume is not available in altair"),
            .bellatrix => @panic("deposit_balance_to_consume is not available in bellatrix"),
            .capella => @panic("deposit_balance_to_consume is not available in capella"),
            .deneb => @panic("deposit_balance_to_consume is not available in deneb"),
            .electra => |state| state.deposit_balance_to_consume,
        };
    }

    pub fn setDepositBalanceToConsume(self: *BeaconStateAllForks, amount: Gwei) void {
        switch (self.*) {
            .phase0 => @panic("deposit_balance_to_consume is not available in phase0"),
            .altair => @panic("deposit_balance_to_consume is not available in altair"),
            .bellatrix => @panic("deposit_balance_to_consume is not available in bellatrix"),
            .capella => @panic("deposit_balance_to_consume is not available in capella"),
            .deneb => @panic("deposit_balance_to_consume is not available in deneb"),
            .electra => |state| state.deposit_balance_to_consume = amount,
        }
    }

    pub fn getExitBalanceToConsume(self: *const BeaconStateAllForks) Gwei {
        return switch (self.*) {
            .phase0 => @panic("exit_balance_to_consume is not available in phase0"),
            .altair => @panic("exit_balance_to_consume is not available in altair"),
            .bellatrix => @panic("exit_balance_to_consume is not available in bellatrix"),
            .capella => @panic("exit_balance_to_consume is not available in capella"),
            .deneb => @panic("exit_balance_to_consume is not available in deneb"),
            .electra => |state| state.exit_balance_to_consume,
        };
    }

    pub fn setExitBalanceToConsume(self: *BeaconStateAllForks, amount: Gwei) void {
        switch (self.*) {
            .phase0 => @panic("exit_balance_to_consume is not available in phase0"),
            .altair => @panic("exit_balance_to_consume is not available in altair"),
            .bellatrix => @panic("exit_balance_to_consume is not available in bellatrix"),
            .capella => @panic("exit_balance_to_consume is not available in capella"),
            .deneb => @panic("exit_balance_to_consume is not available in deneb"),
            .electra => |state| state.exit_balance_to_consume = amount,
        }
    }

    pub fn getEarliestExitEpoch(self: *const BeaconStateAllForks) Epoch {
        return switch (self.*) {
            .phase0 => @panic("earliest_exit_epoch is not available in phase0"),
            .altair => @panic("earliest_exit_epoch is not available in altair"),
            .bellatrix => @panic("earliest_exit_epoch is not available in bellatrix"),
            .capella => @panic("earliest_exit_epoch is not available in capella"),
            .deneb => @panic("earliest_exit_epoch is not available in deneb"),
            .electra => |state| state.earliest_exit_epoch,
        };
    }

    pub fn setEarliestExitEpoch(self: *BeaconStateAllForks, epoch: Epoch) void {
        switch (self.*) {
            .phase0 => @panic("earliest_exit_epoch is not available in phase0"),
            .altair => @panic("earliest_exit_epoch is not available in altair"),
            .bellatrix => @panic("earliest_exit_epoch is not available in bellatrix"),
            .capella => @panic("earliest_exit_epoch is not available in capella"),
            .deneb => @panic("earliest_exit_epoch is not available in deneb"),
            .electra => |state| state.earliest_exit_epoch = epoch,
        }
    }

    pub fn getConsolidationBalanceToConsume(self: *const BeaconStateAllForks) Gwei {
        return switch (self.*) {
            .phase0 => @panic("consolidation_balance_to_consume is not available in phase0"),
            .altair => @panic("consolidation_balance_to_consume is not available in altair"),
            .bellatrix => @panic("consolidation_balance_to_consume is not available in bellatrix"),
            .capella => @panic("consolidation_balance_to_consume is not available in capella"),
            .deneb => @panic("consolidation_balance_to_consume is not available in deneb"),
            .electra => |state| state.consolidation_balance_to_consume,
        };
    }

    pub fn setConsolidationBalanceToConsume(self: *BeaconStateAllForks, amount: Gwei) void {
        switch (self.*) {
            .phase0 => @panic("consolidation_balance_to_consume is not available in phase0"),
            .altair => @panic("consolidation_balance_to_consume is not available in altair"),
            .bellatrix => @panic("consolidation_balance_to_consume is not available in bellatrix"),
            .capella => @panic("consolidation_balance_to_consume is not available in capella"),
            .deneb => @panic("consolidation_balance_to_consume is not available in deneb"),
            .electra => |state| state.consolidation_balance_to_consume = amount,
        }
    }

    pub fn getEarliestConsolidationEpoch(self: *const BeaconStateAllForks) Epoch {
        return switch (self.*) {
            .phase0 => @panic("earliest_consolidation_epoch is not available in phase0"),
            .altair => @panic("earliest_consolidation_epoch is not available in altair"),
            .bellatrix => @panic("earliest_consolidation_epoch is not available in bellatrix"),
            .capella => @panic("earliest_consolidation_epoch is not available in capella"),
            .deneb => @panic("earliest_consolidation_epoch is not available in deneb"),
            .electra => |state| state.earliest_consolidation_epoch,
        };
    }

    pub fn setEarliestConsolidationEpoch(self: *BeaconStateAllForks, epoch: Epoch) void {
        switch (self.*) {
            .phase0 => @panic("earliest_consolidation_epoch is not available in phase0"),
            .altair => @panic("earliest_consolidation_epoch is not available in altair"),
            .bellatrix => @panic("earliest_consolidation_epoch is not available in bellatrix"),
            .capella => @panic("earliest_consolidation_epoch is not available in capella"),
            .deneb => @panic("earliest_consolidation_epoch is not available in deneb"),
            .electra => |state| state.earliest_consolidation_epoch = epoch,
        }
    }

    pub fn getPendingDeposit(self: *const BeaconStateAllForks, index: usize) *const PendingDeposit {
        return switch (self.*) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| &state.pending_deposits[index],
        };
    }

    pub fn getPendingDeposits(self: *const BeaconStateAllForks) []const PendingDeposit {
        return switch (self.*) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits.items,
        };
    }

    pub fn getPendingDepositCount(self: *const BeaconStateAllForks) usize {
        return switch (self.*) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits.len,
        };
    }

    pub fn setPendingDeposit(self: *BeaconStateAllForks, index: usize, deposit: *const PendingDeposit) void {
        switch (self.*) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits[index] = *deposit,
        }
    }

    pub fn addPendingDeposit(self: *BeaconStateAllForks, pending_deposit: *const PendingDeposit) !void {
        switch (self.*) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits.append(*pending_deposit),
        }
    }

    // TODO(ssz): implement sliceFrom api for TreeView
    pub fn sliceFromPendingDeposits(self: *BeaconStateAllForks, start_index: usize) !std.ArrayListUnmanaged(ssz.electra.PendingDeposit) {
        switch (self.*) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| {
                if (start_index >= state.pending_deposits.len) return error.IndexOutOfBounds;
                const new_array = try std.ArrayListUnmanaged(ssz.electra.PendingDeposit).initCapacity(state.pending_deposits.items.len - start_index);
                try new_array.appendSlice(state.pending_deposits.items[start_index..]);
                return new_array;
            },
        }
    }

    pub fn setPendingDeposits(self: *BeaconStateAllForks, deposits: std.ArrayListUnmanaged(ssz.electra.PendingDeposit)) void {
        switch (self.*) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits = deposits,
        }
    }

    pub fn getPendingPartialWithdrawal(self: *const BeaconStateAllForks, index: usize) *const PendingPartialWithdrawal {
        return switch (self.*) {
            .phase0 => @panic("pending_partial_withdrawals is not available in phase0"),
            .altair => @panic("pending_partial_withdrawals is not available in altair"),
            .bellatrix => @panic("pending_partial_withdrawals is not available in bellatrix"),
            .capella => @panic("pending_partial_withdrawals is not available in capella"),
            .deneb => @panic("pending_partial_withdrawals is not available in deneb"),
            .electra => |state| &state.pending_partial_withdrawals[index],
        };
    }

    pub fn sliceFromPendingPartialWithdrawals(self: *const BeaconStateAllForks, start_index: usize) !std.ArrayListUnmanaged(PendingPartialWithdrawal) {
        switch (self.*) {
            .phase0 => @panic("pending_partial_withdrawals is not available in phase0"),
            .altair => @panic("pending_partial_withdrawals is not available in altair"),
            .bellatrix => @panic("pending_partial_withdrawals is not available in bellatrix"),
            .capella => @panic("pending_partial_withdrawals is not available in capella"),
            .deneb => @panic("pending_partial_withdrawals is not available in deneb"),
            .electra => |state| {
                if (start_index >= state.pending_partial_withdrawals.len) return error.IndexOutOfBounds;
                const new_array = try std.ArrayListUnmanaged(PendingPartialWithdrawal).initCapacity(state.pending_partial_withdrawals.items.len - start_index);
                try new_array.appendSlice(state.pending_partial_withdrawals.items[start_index..]);
                return new_array;
            },
        }
    }

    pub fn getPendingPartialWithdrawalCount(self: *const BeaconStateAllForks) usize {
        return switch (self.*) {
            .phase0 => @panic("pending_partial_withdrawals is not available in phase0"),
            .altair => @panic("pending_partial_withdrawals is not available in altair"),
            .bellatrix => @panic("pending_partial_withdrawals is not available in bellatrix"),
            .capella => @panic("pending_partial_withdrawals is not available in capella"),
            .deneb => @panic("pending_partial_withdrawals is not available in deneb"),
            .electra => |state| state.pending_partial_withdrawals.len,
        };
    }

    pub fn setPendingPartialWithdrawal(self: *BeaconStateAllForks, index: usize, withdrawal: *const PendingPartialWithdrawal) void {
        switch (self.*) {
            .phase0 => @panic("pending_partial_withdrawals is not available in phase0"),
            .altair => @panic("pending_partial_withdrawals is not available in altair"),
            .bellatrix => @panic("pending_partial_withdrawals is not available in bellatrix"),
            .capella => @panic("pending_partial_withdrawals is not available in capella"),
            .deneb => @panic("pending_partial_withdrawals is not available in deneb"),
            .electra => |state| state.pending_partial_withdrawals[index] = *withdrawal,
        }
    }

    pub fn setPendingPartialWithdrawals(self: *BeaconStateAllForks, withdrawals: std.ArrayListUnmanaged(PendingPartialWithdrawal)) void {
        switch (self.*) {
            .phase0 => @panic("pending_partial_withdrawals is not available in phase0"),
            .altair => @panic("pending_partial_withdrawals is not available in altair"),
            .bellatrix => @panic("pending_partial_withdrawals is not available in bellatrix"),
            .capella => @panic("pending_partial_withdrawals is not available in capella"),
            .deneb => @panic("pending_partial_withdrawals is not available in deneb"),
            .electra => |state| state.pending_partial_withdrawals = withdrawals,
        }
    }

    pub fn getPendingConsolidation(self: *const BeaconStateAllForks, index: usize) *const PendingConsolidation {
        return switch (self.*) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| &state.pending_consolidations[index],
        };
    }

    pub fn getPendingConsolidations(self: *const BeaconStateAllForks) []const PendingConsolidation {
        return switch (self.*) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| state.pending_consolidations.items,
        };
    }

    pub fn setPendingConsolidation(self: *BeaconStateAllForks, index: usize, consolidation: *const PendingConsolidation) void {
        switch (self.*) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| state.pending_consolidations[index] = *consolidation,
        }
    }

    // TODO: implement sliceFrom api for TreeView
    pub fn sliceFromPendingConsolidations(self: *BeaconStateAllForks, start_index: usize) !std.ArrayListUnmanaged(ssz.electra.PendingConsolidation) {
        switch (self.*) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| {
                if (start_index >= state.pending_consolidations.ites.len) return error.IndexOutOfBounds;
                const new_array = try std.ArrayListUnmanaged(ssz.electra.PendingConsolidation).initCapacity(state.pending_consolidations.items.len - start_index);
                try new_array.appendSlice(state.pending_consolidations.items[start_index..]);
                return new_array;
            },
        }
    }

    pub fn setPendingConsolidations(self: *BeaconStateAllForks, consolidations: std.ArrayListUnmanaged(ssz.electra.PendingConsolidation)) void {
        switch (self.*) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| state.pending_consolidations = consolidations,
        }
    }
};

test "electra - sanity" {
    var electra_state = ssz.electra.BeaconState.default_value;
    electra_state.slot = 12345;
    var beacon_state = BeaconStateAllForks{
        .electra = &electra_state,
    };

    try std.testing.expect(beacon_state.getGenesisTime() == 0);
    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 32, &beacon_state.getGenesisValidatorsRoot());
    try std.testing.expect(beacon_state.getSlot() == 12345);
    beacon_state.setSlot(2025);
    try std.testing.expect(beacon_state.getSlot() == 2025);

    var out: [32]u8 = undefined;
    try beacon_state.hashTreeRoot(std.testing.allocator, &out);
    try expect(!std.mem.eql(u8, &[_]u8{0} ** 32, &out));

    // TODO: more tests
}
