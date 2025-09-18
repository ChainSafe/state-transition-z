const ssz = @import("consensus_types");

pub const Phase0Operations = struct {
    pre: ssz.phase0.BeaconState,
    post: ssz.phase0.BeaconState,
    attestation: ssz.phase0.Attestation,
    attester_slashing: ssz.phase0.AttesterSlashing,
    block: ssz.phase0.BeaconBlock,
    deposit: ssz.phase0.Deposit,
    proposer_slashing: ssz.phase0.ProposerSlashing,
    voluntary_exit: ssz.phase0.SignedVoluntaryExit,
};

pub const AltairOperations = struct {
    pre: ssz.altair.BeaconState,
    post: ssz.altair.BeaconState,
    attestation: ssz.altair.Attestation,
    attester_slashing: ssz.altair.AttesterSlashing,
    block: ssz.altair.BeaconBlock,
    deposit: ssz.altair.Deposit,
    proposer_slashing: ssz.altair.ProposerSlashing,
    voluntary_exit: ssz.altair.SignedVoluntaryExit,
    sync_aggregate: ssz.altair.SyncAggregate,
};

pub const BellatrixOperations = struct {
    pre: ssz.bellatrix.BeaconState,
    post: ssz.bellatrix.BeaconState,
    attestation: ssz.bellatrix.Attestation,
    attester_slashing: ssz.bellatrix.AttesterSlashing,
    block: ssz.bellatrix.BeaconBlock,
    deposit: ssz.bellatrix.Deposit,
    proposer_slashing: ssz.bellatrix.ProposerSlashing,
    voluntary_exit: ssz.bellatrix.SignedVoluntaryExit,
    sync_aggregate: ssz.bellatrix.SyncAggregate,
    body: ssz.bellatrix.BeaconBlockBody,
};

pub const CapellaOperations = struct {
    pre: ssz.capella.BeaconState,
    post: ssz.capella.BeaconState,
    attestation: ssz.capella.Attestation,
    attester_slashing: ssz.capella.AttesterSlashing,
    block: ssz.capella.BeaconBlock,
    deposit: ssz.capella.Deposit,
    proposer_slashing: ssz.capella.ProposerSlashing,
    voluntary_exit: ssz.capella.SignedVoluntaryExit,
    sync_aggregate: ssz.capella.SyncAggregate,
    body: ssz.capella.BeaconBlockBody,
    execution_payload: ssz.capella.ExecutionPayload,
    address_change: ssz.capella.SignedBLSToExecutionChange,
};

pub const DenebOperations = struct {
    pre: ssz.deneb.BeaconState,
    post: ssz.deneb.BeaconState,
    attestation: ssz.deneb.Attestation,
    attester_slashing: ssz.deneb.AttesterSlashing,
    block: ssz.deneb.BeaconBlock,
    deposit: ssz.deneb.Deposit,
    proposer_slashing: ssz.deneb.ProposerSlashing,
    voluntary_exit: ssz.deneb.SignedVoluntaryExit,
    sync_aggregate: ssz.deneb.SyncAggregate,
    body: ssz.deneb.BeaconBlockBody,
    execution_payload: ssz.deneb.ExecutionPayload,
    address_change: ssz.deneb.SignedBLSToExecutionChange,
};

pub const ElectraOperations = struct {
    pre: ssz.electra.BeaconState,
    post: ssz.electra.BeaconState,
    attestation: ssz.electra.Attestation,
    attester_slashing: ssz.electra.AttesterSlashing,
    block: ssz.electra.BeaconBlock,
    deposit: ssz.electra.Deposit,
    proposer_slashing: ssz.electra.ProposerSlashing,
    voluntary_exit: ssz.electra.SignedVoluntaryExit,
    sync_aggregate: ssz.electra.SyncAggregate,
    body: ssz.electra.BeaconBlockBody,
    execution_payload: ssz.electra.ExecutionPayload,
    address_change: ssz.electra.SignedBLSToExecutionChange,
    deposit_request: ssz.electra.DepositRequest,
    withdrawal_request: ssz.electra.WithdrawalRequest,
    consolidation_request: ssz.electra.ConsolidationRequest,
};

pub const Phase0OperationsOut = struct {
    pre: ?*ssz.phase0.BeaconState.Type = null,
    post: ?*ssz.phase0.BeaconState.Type = null,
    attestation: ?*ssz.phase0.Attestation.Type = null,
    attester_slashing: ?*ssz.phase0.AttesterSlashing.Type = null,
    block: ?*ssz.phase0.BeaconBlock.Type = null,
    deposit: ?*ssz.phase0.Deposit.Type = null,
    proposer_slashing: ?*ssz.phase0.ProposerSlashing.Type = null,
    voluntary_exit: ?*ssz.phase0.SignedVoluntaryExit.Type = null,
};

pub const AltairOperationsOut = struct {
    pre: ?*ssz.altair.BeaconState.Type = null,
    post: ?*ssz.altair.BeaconState.Type = null,
    attestation: ?*ssz.altair.Attestation.Type = null,
    attester_slashing: ?*ssz.altair.AttesterSlashing.Type = null,
    block: ?*ssz.altair.BeaconBlock.Type = null,
    deposit: ?*ssz.altair.Deposit.Type = null,
    proposer_slashing: ?*ssz.altair.ProposerSlashing.Type = null,
    voluntary_exit: ?*ssz.altair.SignedVoluntaryExit.Type = null,
    sync_aggregate: ?*ssz.altair.SyncAggregate.Type = null,
};

pub const BellatrixOperationsOut = struct {
    pre: ?*ssz.bellatrix.BeaconState.Type = null,
    post: ?*ssz.bellatrix.BeaconState.Type = null,
    attestation: ?*ssz.bellatrix.Attestation.Type = null,
    attester_slashing: ?*ssz.bellatrix.AttesterSlashing.Type = null,
    block: ?*ssz.bellatrix.BeaconBlock.Type = null,
    deposit: ?*ssz.bellatrix.Deposit.Type = null,
    proposer_slashing: ?*ssz.bellatrix.ProposerSlashing.Type = null,
    voluntary_exit: ?*ssz.bellatrix.SignedVoluntaryExit.Type = null,
    sync_aggregate: ?*ssz.bellatrix.SyncAggregate.Type = null,
    body: ?*ssz.bellatrix.BeaconBlockBody.Type = null,
};

pub const CapellaOperationsOut = struct {
    pre: ?*ssz.capella.BeaconState.Type = null,
    post: ?*ssz.capella.BeaconState.Type = null,
    attestation: ?*ssz.capella.Attestation.Type = null,
    attester_slashing: ?*ssz.capella.AttesterSlashing.Type = null,
    block: ?*ssz.capella.BeaconBlock.Type = null,
    deposit: ?*ssz.capella.Deposit.Type = null,
    proposer_slashing: ?*ssz.capella.ProposerSlashing.Type = null,
    voluntary_exit: ?*ssz.capella.SignedVoluntaryExit.Type = null,
    sync_aggregate: ?*ssz.capella.SyncAggregate.Type = null,
    body: ?*ssz.capella.BeaconBlockBody.Type = null,
    execution_payload: ?*ssz.capella.ExecutionPayload.Type = null,
    address_change: ?*ssz.capella.SignedBLSToExecutionChange.Type = null,
};

pub const DenebOperationsOut = struct {
    pre: ?*ssz.deneb.BeaconState.Type = null,
    post: ?*ssz.deneb.BeaconState.Type = null,
    attestation: ?*ssz.deneb.Attestation.Type = null,
    attester_slashing: ?*ssz.deneb.AttesterSlashing.Type = null,
    block: ?*ssz.deneb.BeaconBlock.Type = null,
    deposit: ?*ssz.deneb.Deposit.Type = null,
    proposer_slashing: ?*ssz.deneb.ProposerSlashing.Type = null,
    voluntary_exit: ?*ssz.deneb.SignedVoluntaryExit.Type = null,
    sync_aggregate: ?*ssz.deneb.SyncAggregate.Type = null,
    body: ?*ssz.deneb.BeaconBlockBody.Type = null,
    execution_payload: ?*ssz.deneb.ExecutionPayload.Type = null,
    address_change: ?*ssz.deneb.SignedBLSToExecutionChange.Type = null,
};

pub const ElectraOperationsOut = struct {
    pre: ?*ssz.electra.BeaconState.Type = null,
    post: ?*ssz.electra.BeaconState.Type = null,
    attestation: ?*ssz.electra.Attestation.Type = null,
    attester_slashing: ?*ssz.electra.AttesterSlashing.Type = null,
    block: ?*ssz.electra.BeaconBlock.Type = null,
    deposit: ?*ssz.electra.Deposit.Type = null,
    proposer_slashing: ?*ssz.electra.ProposerSlashing.Type = null,
    voluntary_exit: ?*ssz.electra.SignedVoluntaryExit.Type = null,
    sync_aggregate: ?*ssz.electra.SyncAggregate.Type = null,
    body: ?*ssz.electra.BeaconBlockBody.Type = null,
    execution_payload: ?*ssz.electra.ExecutionPayload.Type = null,
    address_change: ?*ssz.electra.SignedBLSToExecutionChange.Type = null,
    deposit_request: ?*ssz.electra.DepositRequest.Type = null,
    withdrawal_request: ?*ssz.electra.WithdrawalRequest.Type = null,
    consolidation_request: ?*ssz.electra.ConsolidationRequest.Type = null,
};
