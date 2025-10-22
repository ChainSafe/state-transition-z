const std = @import("std");
const ssz = @import("ssz");
const p = @import("primitive.zig");
const c = @import("constants");
const preset = @import("preset").preset;
const phase0 = @import("phase0.zig");
const altair = @import("altair.zig");
const bellatrix = @import("bellatrix.zig");
const capella = @import("capella.zig");
const deneb = @import("deneb.zig");
const electra = @import("electra.zig");

// Fulu reuses most types from Electra
pub const Fork = phase0.Fork;
pub const ForkData = phase0.ForkData;
pub const Checkpoint = phase0.Checkpoint;
pub const Validator = phase0.Validator;
pub const AttestationData = phase0.AttestationData;
pub const PendingAttestation = phase0.PendingAttestation;
pub const Eth1Data = phase0.Eth1Data;
pub const HistoricalBatch = phase0.HistoricalBatch;
pub const DepositMessage = phase0.DepositMessage;
pub const DepositData = phase0.DepositData;
pub const BeaconBlockHeader = phase0.BeaconBlockHeader;
pub const SigningData = phase0.SigningData;
pub const ProposerSlashing = phase0.ProposerSlashing;
pub const Deposit = phase0.Deposit;
pub const VoluntaryExit = phase0.VoluntaryExit;
pub const SignedVoluntaryExit = phase0.SignedVoluntaryExit;
pub const Eth1Block = phase0.Eth1Block;
pub const HistoricalBlockRoots = phase0.HistoricalBlockRoots;
pub const HistoricalStateRoots = phase0.HistoricalStateRoots;
pub const ProposerSlashings = phase0.ProposerSlashings;
pub const Deposits = phase0.Deposits;
pub const VoluntaryExits = phase0.VoluntaryExits;

pub const SyncAggregate = altair.SyncAggregate;
pub const SyncCommittee = altair.SyncCommittee;
pub const SyncCommitteeMessage = altair.SyncCommitteeMessage;
pub const SyncCommitteeContribution = altair.SyncCommitteeContribution;
pub const ContributionAndProof = altair.ContributionAndProof;
pub const SignedContributionAndProof = altair.SignedContributionAndProof;
pub const SyncAggregatorSelectionData = altair.SyncAggregatorSelectionData;

pub const PowBlock = bellatrix.PowBlock;

pub const Withdrawal = capella.Withdrawal;
pub const BLSToExecutionChange = capella.BLSToExecutionChange;
pub const SignedBLSToExecutionChange = capella.SignedBLSToExecutionChange;
pub const SignedBLSToExecutionChanges = capella.SignedBLSToExecutionChanges;
pub const HistoricalSummary = capella.HistoricalSummary;

pub const BlobIdentifier = deneb.BlobIdentifier;
pub const BlobKzgCommitments = deneb.BlobKzgCommitments;

// Reuse Electra types
pub const PendingDeposit = electra.PendingDeposit;
pub const PendingPartialWithdrawal = electra.PendingPartialWithdrawal;
pub const PendingConsolidation = electra.PendingConsolidation;
pub const DepositRequest = electra.DepositRequest;
pub const WithdrawalRequest = electra.WithdrawalRequest;
pub const ConsolidationRequest = electra.ConsolidationRequest;
pub const ExecutionRequests = electra.ExecutionRequests;
pub const SingleAttestation = electra.SingleAttestation;
pub const Attestation = electra.Attestation;
pub const Attestations = electra.Attestations;
pub const IndexedAttestation = electra.IndexedAttestation;
pub const AttesterSlashing = electra.AttesterSlashing;
pub const AttesterSlashings = electra.AttesterSlashings;
pub const AggregateAndProof = electra.AggregateAndProof;
pub const SignedAggregateAndProof = electra.SignedAggregateAndProof;
pub const SignedBeaconBlockHeader = electra.SignedBeaconBlockHeader;

// Execution payload remains the same as Electra
pub const ExecutionPayload = electra.ExecutionPayload;
pub const ExecutionPayloadHeader = electra.ExecutionPayloadHeader;

// DAS-related custom types
pub const RowIndex = p.Uint64;
pub const ColumnIndex = p.Uint64;
pub const CustodyIndex = p.Uint64;
pub const Cell = ssz.ByteVectorType(c.BYTES_PER_FIELD_ELEMENT * preset.FIELD_ELEMENTS_PER_CELL);

// New containers for Data Availability Sampling
pub const DataColumnSidecar = ssz.VariableContainerType(struct {
    index: ColumnIndex,
    column: ssz.FixedListType(Cell, preset.MAX_BLOB_COMMITMENTS_PER_BLOCK),
    kzg_commitments: ssz.FixedListType(p.KZGCommitment, preset.MAX_BLOB_COMMITMENTS_PER_BLOCK),
    kzg_proofs: ssz.FixedListType(p.KZGProof, preset.MAX_BLOB_COMMITMENTS_PER_BLOCK),
    signed_block_header: SignedBeaconBlockHeader,
    kzg_commitments_inclusion_proof: ssz.FixedVectorType(p.Bytes32, preset.KZG_COMMITMENTS_INCLUSION_PROOF_DEPTH),
});

pub const MatrixEntry = ssz.FixedContainerType(struct {
    cell: Cell,
    kzg_proof: p.KZGProof,
    column_index: ColumnIndex,
    row_index: RowIndex,
});

// Light client types
pub const LightClientHeader = electra.LightClientHeader;
pub const LightClientBootstrap = electra.LightClientBootstrap;
pub const LightClientUpdate = electra.LightClientUpdate;
pub const LightClientFinalityUpdate = electra.LightClientFinalityUpdate;
pub const LightClientOptimisticUpdate = electra.LightClientOptimisticUpdate;

// BeaconBlockBody
pub const BeaconBlockBody = electra.BeaconBlockBody;
pub const BeaconBlock = electra.BeaconBlock;
pub const BlindedBeaconBlockBody = electra.BlindedBeaconBlockBody;
pub const BlindedBeaconBlock = electra.BlindedBeaconBlock;
pub const SignedBlindedBeaconBlock = electra.SignedBlindedBeaconBlock;

// BeaconState with new proposer_lookahead field
pub const BeaconState = ssz.VariableContainerType(struct {
    genesis_time: p.Uint64,
    genesis_validators_root: p.Root,
    slot: p.Slot,
    fork: Fork,
    latest_block_header: BeaconBlockHeader,
    block_roots: HistoricalBlockRoots,
    state_roots: HistoricalStateRoots,
    historical_roots: ssz.FixedListType(p.Root, preset.HISTORICAL_ROOTS_LIMIT),
    eth1_data: Eth1Data,
    eth1_data_votes: phase0.Eth1DataVotes,
    eth1_deposit_index: p.Uint64,
    validators: ssz.FixedListType(Validator, preset.VALIDATOR_REGISTRY_LIMIT),
    balances: ssz.FixedListType(p.Gwei, preset.VALIDATOR_REGISTRY_LIMIT),
    randao_mixes: ssz.FixedVectorType(p.Bytes32, preset.EPOCHS_PER_HISTORICAL_VECTOR),
    slashings: ssz.FixedVectorType(p.Gwei, preset.EPOCHS_PER_SLASHINGS_VECTOR),
    previous_epoch_participation: ssz.FixedListType(p.Uint8, preset.VALIDATOR_REGISTRY_LIMIT),
    current_epoch_participation: ssz.FixedListType(p.Uint8, preset.VALIDATOR_REGISTRY_LIMIT),
    justification_bits: ssz.BitVectorType(c.JUSTIFICATION_BITS_LENGTH),
    previous_justified_checkpoint: Checkpoint,
    current_justified_checkpoint: Checkpoint,
    finalized_checkpoint: Checkpoint,
    inactivity_scores: ssz.FixedListType(p.Uint64, preset.VALIDATOR_REGISTRY_LIMIT),
    current_sync_committee: SyncCommittee,
    next_sync_committee: SyncCommittee,
    latest_execution_payload_header: ExecutionPayloadHeader,
    next_withdrawal_index: p.WithdrawalIndex,
    next_withdrawal_validator_index: p.ValidatorIndex,
    historical_summaries: ssz.FixedListType(HistoricalSummary, preset.HISTORICAL_ROOTS_LIMIT),
    deposit_requests_start_index: p.Uint64,
    deposit_balance_to_consume: p.Gwei,
    exit_balance_to_consume: p.Gwei,
    earliest_exit_epoch: p.Epoch,
    consolidation_balance_to_consume: p.Gwei,
    earliest_consolidation_epoch: p.Epoch,
    pending_deposits: ssz.FixedListType(PendingDeposit, preset.PENDING_DEPOSITS_LIMIT),
    pending_partial_withdrawals: ssz.FixedListType(PendingPartialWithdrawal, preset.PENDING_PARTIAL_WITHDRAWALS_LIMIT),
    pending_consolidations: ssz.FixedListType(PendingConsolidation, preset.PENDING_CONSOLIDATIONS_LIMIT),
    proposer_lookahead: ssz.FixedVectorType(p.ValidatorIndex, (preset.MIN_SEED_LOOKAHEAD + 1) * preset.SLOTS_PER_EPOCH),
});

pub const SignedBeaconBlock = ssz.VariableContainerType(struct {
    message: BeaconBlock,
    signature: p.BLSSignature,
});

// Blob sidecar reuses Electra definition
pub const BlobSidecar = electra.BlobSidecar;
