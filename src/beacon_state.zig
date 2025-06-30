const std = @import("std");
const ssz = @import("consensus_types");
const BeaconStatePhase0 = ssz.phase0.BeaconState.Type;
const BeaconStateAltair = ssz.altair.BeaconState.Type;
const BeaconStateBellatrix = ssz.bellatrix.BeaconState.Type;
const BeaconStateCapella = ssz.capella.BeaconState.Type;
const BeaconStateDeneb = ssz.deneb.BeaconState.Type;
const BeaconStateElectra = ssz.electra.BeaconState.Type;
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
const ExecutionPayloadHeader = ssz.bellatrix.ExecutionPayloadHeader.Type;
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
    phase0: BeaconStatePhase0,
    altair: BeaconStateAltair,
    bellatrix: BeaconStateBellatrix,
    capella: BeaconStateCapella,
    deneb: BeaconStateDeneb,
    electra: BeaconStateElectra,

    pub fn getGenesisTime(self: *const BeaconStateAllForks) u64 {
        return switch (self) {
            .phase0 => |state| state.genesis_time,
            .altair => |state| state.genesis_time,
            .bellatrix => |state| state.genesis_time,
            .capella => |state| state.genesis_time,
            .deneb => |state| state.genesis_time,
            .electra => |state| state.genesis_time,
        };
    }

    pub fn setGenesisTime(self: *BeaconStateAllForks, genesis_time: u64) void {
        switch (self) {
            .phase0 => |state| state.genesis_time = genesis_time,
            .altair => |state| state.genesis_time = genesis_time,
            .bellatrix => |state| state.genesis_time = genesis_time,
            .capella => |state| state.genesis_time = genesis_time,
            .deneb => |state| state.genesis_time = genesis_time,
            .electra => |state| state.genesis_time = genesis_time,
        }
    }

    pub fn getGenesisValidatorsRoot(self: *const BeaconStateAllForks) Root {
        return switch (self) {
            .phase0 => |state| state.genesis_validators_root,
            .altair => |state| state.genesis_validators_root,
            .bellatrix => |state| state.genesis_validators_root,
            .capella => |state| state.genesis_validators_root,
            .deneb => |state| state.genesis_validators_root,
            .electra => |state| state.genesis_validators_root,
        };
    }

    pub fn setGenesisValidatorRoot(self: *BeaconStateAllForks, root: Root) void {
        switch (self) {
            .phase0 => |state| state.genesis_validators_root = root,
            .altair => |state| state.genesis_validators_root = root,
            .bellatrix => |state| state.genesis_validators_root = root,
            .capella => |state| state.genesis_validators_root = root,
            .deneb => |state| state.genesis_validators_root = root,
            .electra => |state| state.genesis_validators_root = root,
        }
    }

    pub fn getSlot(self: *const BeaconStateAllForks) u64 {
        return switch (self) {
            .phase0 => |state| state.slot,
            .altair => |state| state.slot,
            .bellatrix => |state| state.slot,
            .capella => |state| state.slot,
            .deneb => |state| state.slot,
            .electra => |state| state.slot,
        };
    }

    pub fn setSlot(self: *BeaconStateAllForks, slot: u64) void {
        switch (self) {
            .phase0 => |state| state.slot = slot,
            .altair => |state| state.slot = slot,
            .bellatrix => |state| state.slot = slot,
            .capella => |state| state.slot = slot,
            .deneb => |state| state.slot = slot,
            .electra => |state| state.slot = slot,
        }
    }

    pub fn getFork(self: *const BeaconStateAllForks) Fork {
        return switch (self) {
            .phase0 => |state| state.fork,
            .altair => |state| state.fork,
            .bellatrix => |state| state.fork,
            .capella => |state| state.fork,
            .deneb => |state| state.fork,
            .electra => |state| state.fork,
        };
    }

    pub fn setFork(self: *BeaconStateAllForks, fork: Fork) void {
        switch (self) {
            .phase0 => |state| state.fork = fork,
            .altair => |state| state.fork = fork,
            .bellatrix => |state| state.fork = fork,
            .capella => |state| state.fork = fork,
            .deneb => |state| state.fork = fork,
            .electra => |state| state.fork = fork,
        }
    }

    pub fn getLatestBlockHeader(self: *const BeaconStateAllForks) BeaconBlockHeader {
        return switch (self) {
            .phase0 => |state| state.latest_block_header,
            .altair => |state| state.latest_block_header,
            .bellatrix => |state| state.latest_block_header,
            .capella => |state| state.latest_block_header,
            .deneb => |state| state.latest_block_header,
            .electra => |state| state.latest_block_header,
        };
    }

    pub fn setLatestBlockHeader(self: *BeaconStateAllForks, header: BeaconBlockHeader) void {
        switch (self) {
            .phase0 => |state| state.latest_block_header = header,
            .altair => |state| state.latest_block_header = header,
            .bellatrix => |state| state.latest_block_header = header,
            .capella => |state| state.latest_block_header = header,
            .deneb => |state| state.latest_block_header = header,
            .electra => |state| state.latest_block_header = header,
        }
    }

    pub fn getBlockRoot(self: *const BeaconStateAllForks, index: usize) Root {
        return switch (self) {
            .phase0 => |state| state.block_roots[index],
            .altair => |state| state.block_roots[index],
            .bellatrix => |state| state.block_roots[index],
            .capella => |state| state.block_roots[index],
            .deneb => |state| state.block_roots[index],
            .electra => |state| state.block_roots[index],
        };
    }

    pub fn setBlockRoot(self: *BeaconStateAllForks, index: usize, root: Root) void {
        switch (self) {
            .phase0 => |state| state.block_roots[index] = root,
            .altair => |state| state.block_roots[index] = root,
            .bellatrix => |state| state.block_roots[index] = root,
            .capella => |state| state.block_roots[index] = root,
            .deneb => |state| state.block_roots[index] = root,
            .electra => |state| state.block_roots[index] = root,
        }
    }

    pub fn getStateRoot(self: *const BeaconStateAllForks, index: usize) Root {
        return switch (self) {
            .phase0 => |state| state.state_roots[index],
            .altair => |state| state.state_roots[index],
            .bellatrix => |state| state.state_roots[index],
            .capella => |state| state.state_roots[index],
            .deneb => |state| state.state_roots[index],
            .electra => |state| state.state_roots[index],
        };
    }

    pub fn setStateRoot(self: *BeaconStateAllForks, index: usize, root: Root) void {
        switch (self) {
            .phase0 => |state| state.state_roots[index] = root,
            .altair => |state| state.state_roots[index] = root,
            .bellatrix => |state| state.state_roots[index] = root,
            .capella => |state| state.state_roots[index] = root,
            .deneb => |state| state.state_roots[index] = root,
            .electra => |state| state.state_roots[index] = root,
        }
    }

    pub fn getHistoricalRoot(self: *const BeaconStateAllForks, index: usize) Root {
        return switch (self) {
            .phase0 => |state| state.historical_roots[index],
            .altair => |state| state.historical_roots[index],
            .bellatrix => |state| state.historical_roots[index],
            .capella => |state| state.historical_roots[index],
            .deneb => |state| state.historical_roots[index],
            .electra => |state| state.historical_roots[index],
        };
    }

    pub fn setHistoricalRoot(self: *BeaconStateAllForks, index: usize, root: Root) void {
        switch (self) {
            .phase0 => |state| state.historical_roots[index] = root,
            .altair => |state| state.historical_roots[index] = root,
            .bellatrix => |state| state.historical_roots[index] = root,
            .capella => |state| state.historical_roots[index] = root,
            .deneb => |state| state.historical_roots[index] = root,
            .electra => |state| state.historical_roots[index] = root,
        }
    }

    pub fn getEth1Data(self: *const BeaconStateAllForks) Eth1Data {
        return switch (self) {
            .phase0 => |state| state.eth1_data,
            .altair => |state| state.eth1_data,
            .bellatrix => |state| state.eth1_data,
            .capella => |state| state.eth1_data,
            .deneb => |state| state.eth1_data,
            .electra => |state| state.eth1_data,
        };
    }

    pub fn setEth1Data(self: *BeaconStateAllForks, eth1_data: Eth1Data) void {
        switch (self) {
            .phase0 => |state| state.eth1_data = eth1_data,
            .altair => |state| state.eth1_data = eth1_data,
            .bellatrix => |state| state.eth1_data = eth1_data,
            .capella => |state| state.eth1_data = eth1_data,
            .deneb => |state| state.eth1_data = eth1_data,
            .electra => |state| state.eth1_data = eth1_data,
        }
    }

    pub fn getEth1DataVotes(self: *const BeaconStateAllForks) Eth1DataVotes {
        return switch (self) {
            .phase0 => |state| state.eth1_data_votes,
            .altair => |state| state.eth1_data_votes,
            .bellatrix => |state| state.eth1_data_votes,
            .capella => |state| state.eth1_data_votes,
            .deneb => |state| state.eth1_data_votes,
            .electra => |state| state.eth1_data_votes,
        };
    }

    // TODO: fix for other functions
    pub fn setEth1DataVotes(self: *BeaconStateAllForks, eth1_data_votes: Eth1DataVotes) void {
        switch (self.*) {
            .phase0 => |*state| state.eth1_data_votes = eth1_data_votes,
            .altair => |*state| state.eth1_data_votes = eth1_data_votes,
            .bellatrix => |*state| state.eth1_data_votes = eth1_data_votes,
            .capella => |*state| state.eth1_data_votes = eth1_data_votes,
            .deneb => |*state| state.eth1_data_votes = eth1_data_votes,
            .electra => |*state| state.eth1_data_votes = eth1_data_votes,
        }
    }

    pub fn getEth1DepositIndex(self: *const BeaconStateAllForks) u64 {
        return switch (self) {
            .phase0 => |state| state.eth1_deposit_index,
            .altair => |state| state.eth1_deposit_index,
            .bellatrix => |state| state.eth1_deposit_index,
            .capella => |state| state.eth1_deposit_index,
            .deneb => |state| state.eth1_deposit_index,
            .electra => |state| state.eth1_deposit_index,
        };
    }

    pub fn setEth1DepositIndex(self: *BeaconStateAllForks, index: u64) void {
        switch (self) {
            .phase0 => |state| state.eth1_deposit_index = index,
            .altair => |state| state.eth1_deposit_index = index,
            .bellatrix => |state| state.eth1_deposit_index = index,
            .capella => |state| state.eth1_deposit_index = index,
            .deneb => |state| state.eth1_deposit_index = index,
            .electra => |state| state.eth1_deposit_index = index,
        }
    }

    pub fn getValidator(self: *const BeaconStateAllForks, index: usize) Validator {
        return switch (self) {
            .phase0 => |state| state.validators[index],
            .altair => |state| state.validators[index],
            .bellatrix => |state| state.validators[index],
            .capella => |state| state.validators[index],
            .deneb => |state| state.validators[index],
            .electra => |state| state.validators[index],
        };
    }

    pub fn getValidators(self: *const BeaconStateAllForks) Validators {
        return switch (self) {
            .phase0 => |state| state.validators,
            .altair => |state| state.validators,
            .bellatrix => |state| state.validators,
            .capella => |state| state.validators,
            .deneb => |state| state.validators,
            .electra => |state| state.validators,
        };
    }

    pub fn setValidator(self: *BeaconStateAllForks, index: usize, validator: *const Validator) void {
        switch (self) {
            .phase0 => |state| state.validators[index] = *validator,
            .altair => |state| state.validators[index] = *validator,
            .bellatrix => |state| state.validators[index] = *validator,
            .capella => |state| state.validators[index] = *validator,
            .deneb => |state| state.validators[index] = *validator,
            .electra => |state| state.validators[index] = *validator,
        }
    }

    pub fn appendValidator(self: *BeaconStateAllForks, validator: *const Validator) void {
        switch (self) {
            .phase0 => |state| state.validators.append(*validator),
            .altair => |state| state.validators.append(*validator),
            .bellatrix => |state| state.validators.append(*validator),
            .capella => |state| state.validators.append(*validator),
            .deneb => |state| state.validators.append(*validator),
            .electra => |state| state.validators.append(*validator),
        }
    }

    pub fn getBalance(self: *const BeaconStateAllForks, index: usize) u64 {
        return switch (self) {
            .phase0 => |state| state.balances[index],
            .altair => |state| state.balances[index],
            .bellatrix => |state| state.balances[index],
            .capella => |state| state.balances[index],
            .deneb => |state| state.balances[index],
            .electra => |state| state.balances[index],
        };
    }

    pub fn appendBalance(self: *BeaconStateAllForks, amount: u64) void {
        switch (self) {
            .phase0 => |state| state.balances.append(amount),
            .altair => |state| state.balances.append(amount),
            .bellatrix => |state| state.balances.append(amount),
            .capella => |state| state.balances.append(amount),
            .deneb => |state| state.balances.append(amount),
            .electra => |state| state.balances.append(amount),
        }
    }

    pub fn setBalance(self: *BeaconStateAllForks, index: usize, balance: u64) void {
        switch (self) {
            .phase0 => |state| state.balances[index] = balance,
            .altair => |state| state.balances[index] = balance,
            .bellatrix => |state| state.balances[index] = balance,
            .capella => |state| state.balances[index] = balance,
            .deneb => |state| state.balances[index] = balance,
            .electra => |state| state.balances[index] = balance,
        }
    }

    pub fn getValidatorsCount(self: *const BeaconStateAllForks) usize {
        return switch (self) {
            .phase0 => |state| state.validators.len,
            .altair => |state| state.validators.len,
            .bellatrix => |state| state.validators.len,
            .capella => |state| state.validators.len,
            .deneb => |state| state.validators.len,
            .electra => |state| state.validators.len,
        };
    }

    pub fn getRanDaoMix(self: *const BeaconStateAllForks, index: usize) Bytes32 {
        return switch (self) {
            .phase0 => |state| state.randao_mixes[index],
            .altair => |state| state.randao_mixes[index],
            .bellatrix => |state| state.randao_mixes[index],
            .capella => |state| state.randao_mixes[index],
            .deneb => |state| state.randao_mixes[index],
            .electra => |state| state.randao_mixes[index],
        };
    }

    pub fn setRandaoMix(self: *BeaconStateAllForks, index: usize, mix: Bytes32) void {
        switch (self) {
            .phase0 => |state| state.randao_mixes[index] = mix,
            .altair => |state| state.randao_mixes[index] = mix,
            .bellatrix => |state| state.randao_mixes[index] = mix,
            .capella => |state| state.randao_mixes[index] = mix,
            .deneb => |state| state.randao_mixes[index] = mix,
            .electra => |state| state.randao_mixes[index] = mix,
        }
    }

    pub fn getSlashing(self: *const BeaconStateAllForks, index: usize) u64 {
        return switch (self) {
            .phase0 => |state| state.slashings[index],
            .altair => |state| state.slashings[index],
            .bellatrix => |state| state.slashings[index],
            .capella => |state| state.slashings[index],
            .deneb => |state| state.slashings[index],
            .electra => |state| state.slashings[index],
        };
    }

    pub fn getSlashingCount(self: *const BeaconStateAllForks) usize {
        return switch (self) {
            .phase0 => |state| state.slashings.len,
            .altair => |state| state.slashings.len,
            .bellatrix => |state| state.slashings.len,
            .capella => |state| state.slashings.len,
            .deneb => |state| state.slashings.len,
            .electra => |state| state.slashings.len,
        };
    }

    pub fn setSlashing(self: *BeaconStateAllForks, index: usize, slashing: u64) void {
        switch (self) {
            .phase0 => |state| state.slashings[index] = slashing,
            .altair => |state| state.slashings[index] = slashing,
            .bellatrix => |state| state.slashings[index] = slashing,
            .capella => |state| state.slashings[index] = slashing,
            .deneb => |state| state.slashings[index] = slashing,
            .electra => |state| state.slashings[index] = slashing,
        }
    }

    /// only for phase0
    pub fn getPreviousEpochPendingAttestation(self: *const BeaconStateAllForks, index: usize) PendingAttestation {
        return switch (self) {
            .phase0 => |state| state.previous_epoch_attestations[index],
            else => @panic("previous_epoch_pending_attestations is not available post phase0"),
        };
    }

    /// only for phase0
    pub fn getPreviousEpochPendingAttestations(self: *const BeaconStateAllForks) []const PendingAttestation {
        return switch (self) {
            .phase0 => |state| state.previous_epoch_attestations,
            else => @panic("previous_epoch_pending_attestations is not available post phase0"),
        };
    }

    /// only for phase0
    pub fn setPreviousEpochPendingAttestation(self: *BeaconStateAllForks, index: usize, attestation: PendingAttestation) void {
        switch (self) {
            .phase0 => |state| state.previous_epoch_attestations[index] = attestation,
            else => @panic("previous_epoch_pending_attestations is not available post phase0"),
        }
    }

    // only for phase0
    pub fn getCurrentEpochPendingAttestations(self: *const BeaconStateAllForks) []const PendingAttestation {
        return switch (self) {
            .phase0 => |state| state.current_epoch_attestations,
            else => @panic("current_epoch_pending_attestations is not available post phase0"),
        };
    }

    /// from altair, epoch pariticipation is just a byte
    pub fn getPreviousEpochParticipation(self: *const BeaconStateAllForks, index: usize) u8 {
        return switch (self) {
            .phase0 => @panic("previous_epoch_participation is not available in phase0"),
            .altair => |state| state.previous_epoch_participation[index],
            .bellatrix => |state| state.previous_epoch_participation[index],
            .capella => |state| state.previous_epoch_participation[index],
            .deneb => |state| state.previous_epoch_participation[index],
            .electra => |state| state.previous_epoch_participation[index],
        };
    }

    // from altair
    pub fn getPreviousEpochParticipations(self: *const BeaconStateAllForks) []const u8 {
        return switch (self) {
            .phase0 => @panic("previous_epoch_participation is not available in phase0"),
            .altair => |state| state.previous_epoch_participation.items,
            .bellatrix => |state| state.previous_epoch_participation.items,
            .capella => |state| state.previous_epoch_participation.items,
            .deneb => |state| state.previous_epoch_participation.items,
            .electra => |state| state.previous_epoch_participation.items,
        };
    }

    pub fn addPreviousEpochParticipation(self: *BeaconStateAllForks, participation: u8) void {
        switch (self) {
            .phase0 => @panic("previous_epoch_participation is not available in phase0"),
            .altair => |state| state.previous_epoch_participation.append(participation),
            .bellatrix => |state| state.previous_epoch_participation.append(participation),
            .capella => |state| state.previous_epoch_participation.append(participation),
            .deneb => |state| state.previous_epoch_participation.append(participation),
            .electra => |state| state.previous_epoch_participation.append(participation),
        }
    }

    /// from altair, epoch participation is just a byte
    pub fn setPreviousEpochParticipation(self: *BeaconStateAllForks, index: usize, participation: u8) void {
        switch (self) {
            .phase0 => @panic("previous_epoch_participation is not available in phase0"),
            .altair => |state| state.previous_epoch_participation[index] = participation,
            .bellatrix => |state| state.previous_epoch_participation[index] = participation,
            .capella => |state| state.previous_epoch_participation[index] = participation,
            .deneb => |state| state.previous_epoch_participation[index] = participation,
            .electra => |state| state.previous_epoch_participation[index] = participation,
        }
    }

    pub fn getCurrentEpochParticipations(self: *const BeaconStateAllForks) []const u8 {
        return switch (self) {
            .phase0 => @panic("current_epoch_participation is not available in phase0"),
            .altair => |state| state.current_epoch_participation.items,
            .bellatrix => |state| state.current_epoch_participation.items,
            .capella => |state| state.current_epoch_participation.items,
            .deneb => |state| state.current_epoch_participation.items,
            .electra => |state| state.current_epoch_participation.items,
        };
    }

    pub fn addCurrentEpochParticipation(self: *BeaconStateAllForks, participation: u8) void {
        switch (self) {
            .phase0 => @panic("current_epoch_participation is not available in phase0"),
            .altair => |state| state.current_epoch_participation.append(participation),
            .bellatrix => |state| state.current_epoch_participation.append(participation),
            .capella => |state| state.current_epoch_participation.append(participation),
            .deneb => |state| state.current_epoch_participation.append(participation),
            .electra => |state| state.current_epoch_participation.append(participation),
        }
    }

    pub fn getJustificationBits(self: *const BeaconStateAllForks) JustificationBits {
        return switch (self) {
            .phase0 => |state| state.justification_bits,
            .altair => |state| state.justification_bits,
            .bellatrix => |state| state.justification_bits,
            .capella => |state| state.justification_bits,
            .deneb => |state| state.justification_bits,
            .electra => |state| state.justification_bits,
        };
    }

    pub fn setJustificationBits(self: *BeaconStateAllForks, bits: JustificationBits) void {
        switch (self) {
            .phase0 => |state| state.justification_bits = bits,
            .altair => |state| state.justification_bits = bits,
            .bellatrix => |state| state.justification_bits = bits,
            .capella => |state| state.justification_bits = bits,
            .deneb => |state| state.justification_bits = bits,
            .electra => |state| state.justification_bits = bits,
        }
    }

    pub fn getPreviousJustifiedCheckpoint(self: *const BeaconStateAllForks) Checkpoint {
        return switch (self) {
            .phase0 => |state| state.previous_justified_checkpoint,
            .altair => |state| state.previous_justified_checkpoint,
            .bellatrix => |state| state.previous_justified_checkpoint,
            .capella => |state| state.previous_justified_checkpoint,
            .deneb => |state| state.previous_justified_checkpoint,
            .electra => |state| state.previous_justified_checkpoint,
        };
    }

    pub fn setPreviousJustifiedCheckpoint(self: *BeaconStateAllForks, checkpoint: Checkpoint) void {
        switch (self) {
            .phase0 => |state| state.previous_justified_checkpoint = checkpoint,
            .altair => |state| state.previous_justified_checkpoint = checkpoint,
            .bellatrix => |state| state.previous_justified_checkpoint = checkpoint,
            .capella => |state| state.previous_justified_checkpoint = checkpoint,
            .deneb => |state| state.previous_justified_checkpoint = checkpoint,
            .electra => |state| state.previous_justified_checkpoint = checkpoint,
        }
    }

    pub fn getCurrentJustifiedCheckpoint(self: *const BeaconStateAllForks) Checkpoint {
        return switch (self) {
            .phase0 => |state| state.current_justified_checkpoint,
            .altair => |state| state.current_justified_checkpoint,
            .bellatrix => |state| state.current_justified_checkpoint,
            .capella => |state| state.current_justified_checkpoint,
            .deneb => |state| state.current_justified_checkpoint,
            .electra => |state| state.current_justified_checkpoint,
        };
    }

    pub fn setCurrentJustifiedCheckpoint(self: *BeaconStateAllForks, checkpoint: Checkpoint) void {
        switch (self) {
            .phase0 => |state| state.current_justified_checkpoint = checkpoint,
            .altair => |state| state.current_justified_checkpoint = checkpoint,
            .bellatrix => |state| state.current_justified_checkpoint = checkpoint,
            .capella => |state| state.current_justified_checkpoint = checkpoint,
            .deneb => |state| state.current_justified_checkpoint = checkpoint,
            .electra => |state| state.current_justified_checkpoint = checkpoint,
        }
    }

    pub fn getFinalizedCheckpoint(self: *const BeaconStateAllForks) Checkpoint {
        return switch (self) {
            .phase0 => |state| state.finalized_checkpoint,
            .altair => |state| state.finalized_checkpoint,
            .bellatrix => |state| state.finalized_checkpoint,
            .capella => |state| state.finalized_checkpoint,
            .deneb => |state| state.finalized_checkpoint,
            .electra => |state| state.finalized_checkpoint,
        };
    }

    pub fn setFinalizedCheckpoint(self: *BeaconStateAllForks, checkpoint: Checkpoint) void {
        switch (self) {
            .phase0 => |state| state.finalized_checkpoint = checkpoint,
            .altair => |state| state.finalized_checkpoint = checkpoint,
            .bellatrix => |state| state.finalized_checkpoint = checkpoint,
            .capella => |state| state.finalized_checkpoint = checkpoint,
            .deneb => |state| state.finalized_checkpoint = checkpoint,
            .electra => |state| state.finalized_checkpoint = checkpoint,
        }
    }

    pub fn getInactivityScore(self: *const BeaconStateAllForks, index: usize) u64 {
        return switch (self) {
            .phase0 => @panic("inactivity_scores is not available in phase0"),
            .altair => |state| state.inactivity_scores[index],
            .bellatrix => |state| state.inactivity_scores[index],
            .capella => |state| state.inactivity_scores[index],
            .deneb => |state| state.inactivity_scores[index],
            .electra => |state| state.inactivity_scores[index],
        };
    }

    pub fn setInactivityScore(self: *BeaconStateAllForks, index: usize, score: u64) void {
        switch (self) {
            .phase0 => @panic("inactivity_scores is not available in phase0"),
            .altair => |state| state.inactivity_scores[index] = score,
            .bellatrix => |state| state.inactivity_scores[index] = score,
            .capella => |state| state.inactivity_scores[index] = score,
            .deneb => |state| state.inactivity_scores[index] = score,
            .electra => |state| state.inactivity_scores[index] = score,
        }
    }

    pub fn addInactivityScore(self: *BeaconStateAllForks, score: u64) void {
        switch (self) {
            .phase0 => @panic("inactivity_scores is not available in phase0"),
            .altair => |state| state.inactivity_scores.append(score),
            .bellatrix => |state| state.inactivity_scores.append(score),
            .capella => |state| state.inactivity_scores.append(score),
            .deneb => |state| state.inactivity_scores.append(score),
            .electra => |state| state.inactivity_scores.append(score),
        }
    }

    pub fn getCurrentSyncCommittee(self: *const BeaconStateAllForks) SyncCommittee {
        return switch (self) {
            .phase0 => @panic("current_sync_committee is not available in phase0"),
            .altair => |state| state.current_sync_committee,
            .bellatrix => |state| state.current_sync_committee,
            .capella => |state| state.current_sync_committee,
            .deneb => |state| state.current_sync_committee,
            .electra => |state| state.current_sync_committee,
        };
    }

    pub fn setCurrentSyncCommittee(self: *BeaconStateAllForks, sync_committee: SyncCommittee) void {
        switch (self) {
            .phase0 => @panic("current_sync_committee is not available in phase0"),
            .altair => |state| state.current_sync_committee = sync_committee,
            .bellatrix => |state| state.current_sync_committee = sync_committee,
            .capella => |state| state.current_sync_committee = sync_committee,
            .deneb => |state| state.current_sync_committee = sync_committee,
            .electra => |state| state.current_sync_committee = sync_committee,
        }
    }

    pub fn getNextSyncCommittee(self: *const BeaconStateAllForks) SyncCommittee {
        return switch (self) {
            .phase0 => @panic("next_sync_committee is not available in phase0"),
            .altair => |state| state.next_sync_committee,
            .bellatrix => |state| state.next_sync_committee,
            .capella => |state| state.next_sync_committee,
            .deneb => |state| state.next_sync_committee,
            .electra => |state| state.next_sync_committee,
        };
    }

    pub fn setNextSyncCommittee(self: *BeaconStateAllForks, sync_committee: SyncCommittee) void {
        switch (self) {
            .phase0 => @panic("next_sync_committee is not available in phase0"),
            .altair => |state| state.next_sync_committee = sync_committee,
            .bellatrix => |state| state.next_sync_committee = sync_committee,
            .capella => |state| state.next_sync_committee = sync_committee,
            .deneb => |state| state.next_sync_committee = sync_committee,
            .electra => |state| state.next_sync_committee = sync_committee,
        }
    }

    pub fn getLatestExecutionPayloadHeader(self: *const BeaconStateAllForks) ExecutionPayloadHeader {
        return switch (self) {
            .phase0 => @panic("latest_execution_payload_header is not available in phase0"),
            .altair => @panic("latest_execution_payload_header is not available in altair"),
            .bellatrix => |state| state.latest_execution_payload_header,
            .capella => |state| state.latest_execution_payload_header,
            .deneb => |state| state.latest_execution_payload_header,
            .electra => |state| state.latest_execution_payload_header,
        };
    }

    pub fn setLatestExecutionPayloadHeader(self: *BeaconStateAllForks, header: ExecutionPayloadHeader) void {
        switch (self) {
            .phase0 => @panic("latest_execution_payload_header is not available in phase0"),
            .altair => @panic("latest_execution_payload_header is not available in altair"),
            .bellatrix => |state| state.latest_execution_payload_header = header,
            .capella => |state| state.latest_execution_payload_header = header,
            .deneb => |state| state.latest_execution_payload_header = header,
            .electra => |state| state.latest_execution_payload_header = header,
        }
    }

    pub fn getNextWithdrawalIndex(self: *const BeaconStateAllForks) u64 {
        return switch (self) {
            .phase0 => @panic("next_withdrawal_index is not available in phase0"),
            .altair => @panic("next_withdrawal_index is not available in altair"),
            .bellatrix => @panic("next_withdrawal_index is not available in bellatrix"),
            .capella => |state| state.next_withdrawal_index,
            .deneb => |state| state.next_withdrawal_index,
            .electra => |state| state.next_withdrawal_index,
        };
    }

    pub fn setNextWithdrawalIndex(self: *BeaconStateAllForks, index: u64) void {
        switch (self) {
            .phase0 => @panic("next_withdrawal_index is not available in phase0"),
            .altair => @panic("next_withdrawal_index is not available in altair"),
            .bellatrix => @panic("next_withdrawal_index is not available in bellatrix"),
            .capella => |state| state.next_withdrawal_index = index,
            .deneb => |state| state.next_withdrawal_index = index,
            .electra => |state| state.next_withdrawal_index = index,
        }
    }

    pub fn getNextWithdrawalValidatorIndex(self: *const BeaconStateAllForks) u64 {
        return switch (self) {
            .phase0 => @panic("next_withdrawal_validator_index is not available in phase0"),
            .altair => @panic("next_withdrawal_validator_index is not available in altair"),
            .bellatrix => @panic("next_withdrawal_validator_index is not available in bellatrix"),
            .capella => |state| state.next_withdrawal_validator_index,
            .deneb => |state| state.next_withdrawal_validator_index,
            .electra => |state| state.next_withdrawal_validator_index,
        };
    }

    pub fn setNextWithdrawalValidatorIndex(self: *BeaconStateAllForks, index: u64) void {
        switch (self) {
            .phase0 => @panic("next_withdrawal_validator_index is not available in phase0"),
            .altair => @panic("next_withdrawal_validator_index is not available in altair"),
            .bellatrix => @panic("next_withdrawal_validator_index is not available in bellatrix"),
            .capella => |state| state.next_withdrawal_validator_index = index,
            .deneb => |state| state.next_withdrawal_validator_index = index,
            .electra => |state| state.next_withdrawal_validator_index = index,
        }
    }

    pub fn getHistoricalSummary(self: *const BeaconStateAllForks, index: usize) HistoricalSummary {
        return switch (self) {
            .phase0 => @panic("historical_summary is not available in phase0"),
            .altair => @panic("historical_summary is not available in altair"),
            .bellatrix => @panic("historical_summary is not available in bellatrix"),
            .capella => |state| state.historical_summaries[index],
            .deneb => |state| state.historical_summaries[index],
            .electra => |state| state.historical_summaries[index],
        };
    }

    pub fn setHistoricalSummary(self: *BeaconStateAllForks, index: usize, summary: HistoricalSummary) void {
        switch (self) {
            .phase0 => @panic("historical_summary is not available in phase0"),
            .altair => @panic("historical_summary is not available in altair"),
            .bellatrix => @panic("historical_summary is not available in bellatrix"),
            .capella => |state| state.historical_summaries[index] = summary,
            .deneb => |state| state.historical_summaries[index] = summary,
            .electra => |state| state.historical_summaries[index] = summary,
        }
    }

    pub fn getDepositRequestsStartIndex(self: *const BeaconStateAllForks) u64 {
        return switch (self) {
            .phase0 => @panic("deposit_requests_start_index is not available in phase0"),
            .altair => @panic("deposit_requests_start_index is not available in altair"),
            .bellatrix => @panic("deposit_requests_start_index is not available in bellatrix"),
            .capella => @panic("deposit_requests_start_index is not available in capella"),
            .deneb => @panic("deposit_requests_start_index is not available in deneb"),
            .electra => |state| state.deposit_requests_start_index,
        };
    }

    pub fn setDepositRequestsStartIndex(self: *BeaconStateAllForks, index: u64) void {
        switch (self) {
            .phase0 => @panic("deposit_requests_start_index is not available in phase0"),
            .altair => @panic("deposit_requests_start_index is not available in altair"),
            .bellatrix => @panic("deposit_requests_start_index is not available in bellatrix"),
            .capella => @panic("deposit_requests_start_index is not available in capella"),
            .deneb => @panic("deposit_requests_start_index is not available in deneb"),
            .electra => |state| state.deposit_requests_start_index = index,
        }
    }

    pub fn getDepositBalanceToConsume(self: *const BeaconStateAllForks) Gwei {
        return switch (self) {
            .phase0 => @panic("deposit_balance_to_consume is not available in phase0"),
            .altair => @panic("deposit_balance_to_consume is not available in altair"),
            .bellatrix => @panic("deposit_balance_to_consume is not available in bellatrix"),
            .capella => @panic("deposit_balance_to_consume is not available in capella"),
            .deneb => @panic("deposit_balance_to_consume is not available in deneb"),
            .electra => |state| state.deposit_balance_to_consume,
        };
    }

    pub fn setDepositBalanceToConsume(self: *BeaconStateAllForks, amount: Gwei) void {
        switch (self) {
            .phase0 => @panic("deposit_balance_to_consume is not available in phase0"),
            .altair => @panic("deposit_balance_to_consume is not available in altair"),
            .bellatrix => @panic("deposit_balance_to_consume is not available in bellatrix"),
            .capella => @panic("deposit_balance_to_consume is not available in capella"),
            .deneb => @panic("deposit_balance_to_consume is not available in deneb"),
            .electra => |state| state.deposit_balance_to_consume = amount,
        }
    }

    pub fn getExitBalanceToConsume(self: *const BeaconStateAllForks) Gwei {
        return switch (self) {
            .phase0 => @panic("exit_balance_to_consume is not available in phase0"),
            .altair => @panic("exit_balance_to_consume is not available in altair"),
            .bellatrix => @panic("exit_balance_to_consume is not available in bellatrix"),
            .capella => @panic("exit_balance_to_consume is not available in capella"),
            .deneb => @panic("exit_balance_to_consume is not available in deneb"),
            .electra => |state| state.exit_balance_to_consume,
        };
    }

    pub fn setExitBalanceToConsume(self: *BeaconStateAllForks, amount: Gwei) void {
        switch (self) {
            .phase0 => @panic("exit_balance_to_consume is not available in phase0"),
            .altair => @panic("exit_balance_to_consume is not available in altair"),
            .bellatrix => @panic("exit_balance_to_consume is not available in bellatrix"),
            .capella => @panic("exit_balance_to_consume is not available in capella"),
            .deneb => @panic("exit_balance_to_consume is not available in deneb"),
            .electra => |state| state.exit_balance_to_consume = amount,
        }
    }

    pub fn getEarliestExitEpoch(self: *const BeaconStateAllForks) Epoch {
        return switch (self) {
            .phase0 => @panic("earliest_exit_epoch is not available in phase0"),
            .altair => @panic("earliest_exit_epoch is not available in altair"),
            .bellatrix => @panic("earliest_exit_epoch is not available in bellatrix"),
            .capella => @panic("earliest_exit_epoch is not available in capella"),
            .deneb => @panic("earliest_exit_epoch is not available in deneb"),
            .electra => |state| state.earliest_exit_epoch,
        };
    }

    pub fn setEarliestExitEpoch(self: *BeaconStateAllForks, epoch: Epoch) void {
        switch (self) {
            .phase0 => @panic("earliest_exit_epoch is not available in phase0"),
            .altair => @panic("earliest_exit_epoch is not available in altair"),
            .bellatrix => @panic("earliest_exit_epoch is not available in bellatrix"),
            .capella => @panic("earliest_exit_epoch is not available in capella"),
            .deneb => @panic("earliest_exit_epoch is not available in deneb"),
            .electra => |state| state.earliest_exit_epoch = epoch,
        }
    }

    pub fn getConsolidationBalanceToConsume(self: *const BeaconStateAllForks) Gwei {
        return switch (self) {
            .phase0 => @panic("consolidation_balance_to_consume is not available in phase0"),
            .altair => @panic("consolidation_balance_to_consume is not available in altair"),
            .bellatrix => @panic("consolidation_balance_to_consume is not available in bellatrix"),
            .capella => @panic("consolidation_balance_to_consume is not available in capella"),
            .deneb => @panic("consolidation_balance_to_consume is not available in deneb"),
            .electra => |state| state.consolidation_balance_to_consume,
        };
    }

    pub fn setConsolidationBalanceToConsume(self: *BeaconStateAllForks, amount: Gwei) void {
        switch (self) {
            .phase0 => @panic("consolidation_balance_to_consume is not available in phase0"),
            .altair => @panic("consolidation_balance_to_consume is not available in altair"),
            .bellatrix => @panic("consolidation_balance_to_consume is not available in bellatrix"),
            .capella => @panic("consolidation_balance_to_consume is not available in capella"),
            .deneb => @panic("consolidation_balance_to_consume is not available in deneb"),
            .electra => |state| state.consolidation_balance_to_consume = amount,
        }
    }

    pub fn getEarliestConsolidationEpoch(self: *const BeaconStateAllForks) Epoch {
        return switch (self) {
            .phase0 => @panic("earliest_consolidation_epoch is not available in phase0"),
            .altair => @panic("earliest_consolidation_epoch is not available in altair"),
            .bellatrix => @panic("earliest_consolidation_epoch is not available in bellatrix"),
            .capella => @panic("earliest_consolidation_epoch is not available in capella"),
            .deneb => @panic("earliest_consolidation_epoch is not available in deneb"),
            .electra => |state| state.earliest_consolidation_epoch,
        };
    }

    pub fn setEarliestConsolidationEpoch(self: *BeaconStateAllForks, epoch: Epoch) void {
        switch (self) {
            .phase0 => @panic("earliest_consolidation_epoch is not available in phase0"),
            .altair => @panic("earliest_consolidation_epoch is not available in altair"),
            .bellatrix => @panic("earliest_consolidation_epoch is not available in bellatrix"),
            .capella => @panic("earliest_consolidation_epoch is not available in capella"),
            .deneb => @panic("earliest_consolidation_epoch is not available in deneb"),
            .electra => |state| state.earliest_consolidation_epoch = epoch,
        }
    }

    pub fn getPendingDeposit(self: *const BeaconStateAllForks, index: usize) PendingDeposit {
        return switch (self) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits[index],
        };
    }

    pub fn getPendingDeposits(self: *const BeaconStateAllForks) []const PendingDeposit {
        return switch (self) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits.items,
        };
    }

    pub fn getPendingDepositCount(self: *const BeaconStateAllForks) usize {
        return switch (self) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits.len,
        };
    }

    pub fn setPendingDeposit(self: *BeaconStateAllForks, index: usize, deposit: PendingDeposit) void {
        switch (self) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits[index] = deposit,
        }
    }

    pub fn addPendingDeposit(self: *BeaconStateAllForks, pending_deposit: PendingDeposit) !void {
        switch (self) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits.append(pending_deposit),
        }
    }

    // TODO(ssz): implement sliceFrom api for TreeView
    pub fn sliceFromPendingDeposits(self: *BeaconStateAllForks, start_index: usize) !std.ArrayListUnmanaged(ssz.electra.PendingDeposit) {
        switch (self) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| try state.pending_deposits.sliceFrom(start_index),
        }
    }

    pub fn setPendingDeposits(self: *BeaconStateAllForks, deposits: std.ArrayListUnmanaged(ssz.electra.PendingDeposit)) void {
        switch (self) {
            .phase0 => @panic("pending_deposits is not available in phase0"),
            .altair => @panic("pending_deposits is not available in altair"),
            .bellatrix => @panic("pending_deposits is not available in bellatrix"),
            .capella => @panic("pending_deposits is not available in capella"),
            .deneb => @panic("pending_deposits is not available in deneb"),
            .electra => |state| state.pending_deposits = deposits,
        }
    }

    pub fn getPendingPartialWithdrawal(self: *const BeaconStateAllForks, index: usize) PendingPartialWithdrawal {
        return switch (self) {
            .phase0 => @panic("pending_partial_withdrawals is not available in phase0"),
            .altair => @panic("pending_partial_withdrawals is not available in altair"),
            .bellatrix => @panic("pending_partial_withdrawals is not available in bellatrix"),
            .capella => @panic("pending_partial_withdrawals is not available in capella"),
            .deneb => @panic("pending_partial_withdrawals is not available in deneb"),
            .electra => |state| state.pending_partial_withdrawals[index],
        };
    }

    pub fn getPendingPartialWithdrawalCount(self: *const BeaconStateAllForks) usize {
        return switch (self) {
            .phase0 => @panic("pending_partial_withdrawals is not available in phase0"),
            .altair => @panic("pending_partial_withdrawals is not available in altair"),
            .bellatrix => @panic("pending_partial_withdrawals is not available in bellatrix"),
            .capella => @panic("pending_partial_withdrawals is not available in capella"),
            .deneb => @panic("pending_partial_withdrawals is not available in deneb"),
            .electra => |state| state.pending_partial_withdrawals.len,
        };
    }

    pub fn setPendingPartialWithdrawal(self: *BeaconStateAllForks, index: usize, withdrawal: PendingPartialWithdrawal) void {
        switch (self) {
            .phase0 => @panic("pending_partial_withdrawals is not available in phase0"),
            .altair => @panic("pending_partial_withdrawals is not available in altair"),
            .bellatrix => @panic("pending_partial_withdrawals is not available in bellatrix"),
            .capella => @panic("pending_partial_withdrawals is not available in capella"),
            .deneb => @panic("pending_partial_withdrawals is not available in deneb"),
            .electra => |state| state.pending_partial_withdrawals[index] = withdrawal,
        }
    }

    pub fn getPendingConsolidation(self: *const BeaconStateAllForks, index: usize) PendingConsolidation {
        return switch (self) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| state.pending_consolidations[index],
        };
    }

    pub fn getPendingConsolidations(self: *const BeaconStateAllForks) []const PendingConsolidation {
        return switch (self) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| state.pending_consolidations.items,
        };
    }

    pub fn setPendingConsolidation(self: *BeaconStateAllForks, index: usize, consolidation: PendingConsolidation) void {
        switch (self) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| state.pending_consolidations[index] = consolidation,
        }
    }

    // TODO: implement sliceFrom api
    pub fn sliceFromPendingConsolidations(self: *BeaconStateAllForks, start_index: usize) !std.ArrayListUnmanaged(ssz.electra.PendingConsolidation) {
        switch (self) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| try state.pending_consolidations.sliceFrom(start_index),
        }
    }

    pub fn setPendingConsolidations(self: *BeaconStateAllForks, consolidations: std.ArrayListUnmanaged(ssz.electra.PendingConsolidation)) void {
        switch (self) {
            .phase0 => @panic("pending_consolidations is not available in phase0"),
            .altair => @panic("pending_consolidations is not available in altair"),
            .bellatrix => @panic("pending_consolidations is not available in bellatrix"),
            .capella => @panic("pending_consolidations is not available in capella"),
            .deneb => @panic("pending_consolidations is not available in deneb"),
            .electra => |state| state.pending_consolidations = consolidations,
        }
    }
};
