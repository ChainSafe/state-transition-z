const consensus_types = @import("consensus_types");
const phase0 = consensus_types.phase0;
const altair = consensus_types.altair;
const bellatrix = consensus_types.bellatrix;
const capella = consensus_types.capella;
const deneb = consensus_types.deneb;
const electra = consensus_types.electra;

pub const Phase0Operations = struct {
    pre: phase0.BeaconState,
    post: phase0.BeaconState,
    attestation: phase0.Attestation,
    attester_slashing: phase0.AttesterSlashing,
    block: phase0.BeaconBlock,
    deposit: phase0.Deposit,
    proposer_slashing: phase0.ProposerSlashing,
    voluntary_exit: phase0.VoluntaryExit,
};

pub const AltairOperations = struct {
    pre: altair.BeaconState,
    post: altair.BeaconState,
    attestation: altair.Attestation,
    attester_slashing: altair.AttesterSlashing,
    block: altair.BeaconBlock,
    deposit: altair.Deposit,
    proposer_slashing: altair.ProposerSlashing,
    voluntary_exit: altair.VoluntaryExit,
    sync_aggregate: altair.SyncAggregate,
};

pub const BellatrixOperations = struct {
    pre: bellatrix.BeaconState,
    post: bellatrix.BeaconState,
    attestation: bellatrix.Attestation,
    attester_slashing: bellatrix.AttesterSlashing,
    block: bellatrix.BeaconBlock,
    deposit: bellatrix.Deposit,
    proposer_slashing: bellatrix.ProposerSlashing,
    voluntary_exit: bellatrix.VoluntaryExit,
    sync_aggregate: bellatrix.SyncAggregate,
    body: bellatrix.BeaconBlockBody,
};

pub const CapellaOperations = struct {
    pre: capella.BeaconState,
    post: capella.BeaconState,
    attestation: capella.Attestation,
    attester_slashing: capella.AttesterSlashing,
    block: capella.BeaconBlock,
    deposit: capella.Deposit,
    proposer_slashing: capella.ProposerSlashing,
    voluntary_exit: capella.VoluntaryExit,
    sync_aggregate: capella.SyncAggregate,
    body: capella.BeaconBlockBody,
    execution_payload: capella.ExecutionPayload,
    address_change: capella.SignedBLSToExecutionChange,
};

pub const DenebOperations = struct {
    pre: deneb.BeaconState,
    post: deneb.BeaconState,
    attestation: deneb.Attestation,
    attester_slashing: deneb.AttesterSlashing,
    block: deneb.BeaconBlock,
    deposit: deneb.Deposit,
    proposer_slashing: deneb.ProposerSlashing,
    voluntary_exit: deneb.VoluntaryExit,
    sync_aggregate: deneb.SyncAggregate,
    body: deneb.BeaconBlockBody,
    execution_payload: deneb.ExecutionPayload,
    address_change: deneb.SignedBLSToExecutionChange,
};

pub const ElectraOperations = struct {
    pre: electra.BeaconState,
    post: electra.BeaconState,
    attestation: electra.Attestation,
    attester_slashing: electra.AttesterSlashing,
    block: electra.BeaconBlock,
    deposit: electra.Deposit,
    proposer_slashing: electra.ProposerSlashing,
    voluntary_exit: electra.VoluntaryExit,
    sync_aggregate: electra.SyncAggregate,
    body: electra.BeaconBlockBody,
    execution_payload: electra.ExecutionPayload,
    address_change: electra.SignedBLSToExecutionChange,
    deposit_request: electra.DepositRequest,
    withdrawal_request: electra.WithdrawalRequest,
    consolidation_request: electra.ConsolidationRequest,
};

pub const Phase0OperationsOut = struct {
    pre: ?*phase0.BeaconState.Type = null,
    post: ?*phase0.BeaconState.Type = null,
    attestation: ?*phase0.Attestation.Type = null,
    attester_slashing: ?*phase0.AttesterSlashing.Type = null,
    block: ?*phase0.BeaconBlock.Type = null,
    deposit: ?*phase0.Deposit.Type = null,
    proposer_slashing: ?*phase0.ProposerSlashing.Type = null,
    voluntary_exit: ?*phase0.VoluntaryExit.Type = null,
};

pub const AltairOperationsOut = struct {
    pre: ?*altair.BeaconState.Type = null,
    post: ?*altair.BeaconState.Type = null,
    attestation: ?*altair.Attestation.Type = null,
    attester_slashing: ?*altair.AttesterSlashing.Type = null,
    block: ?*altair.BeaconBlock.Type = null,
    deposit: ?*altair.Deposit.Type = null,
    proposer_slashing: ?*altair.ProposerSlashing.Type = null,
    voluntary_exit: ?*altair.VoluntaryExit.Type = null,
    sync_aggregate: ?*altair.SyncAggregate.Type = null,
};

pub const BellatrixOperationsOut = struct {
    pre: ?*bellatrix.BeaconState.Type = null,
    post: ?*bellatrix.BeaconState.Type = null,
    attestation: ?*bellatrix.Attestation.Type = null,
    attester_slashing: ?*bellatrix.AttesterSlashing.Type = null,
    block: ?*bellatrix.BeaconBlock.Type = null,
    deposit: ?*bellatrix.Deposit.Type = null,
    proposer_slashing: ?*bellatrix.ProposerSlashing.Type = null,
    voluntary_exit: ?*bellatrix.VoluntaryExit.Type = null,
    sync_aggregate: ?*bellatrix.SyncAggregate.Type = null,
    body: ?*bellatrix.BeaconBlockBody.Type = null,
};

pub const CapellaOperationsOut = struct {
    pre: ?*capella.BeaconState.Type = null,
    post: ?*capella.BeaconState.Type = null,
    attestation: ?*capella.Attestation.Type = null,
    attester_slashing: ?*capella.AttesterSlashing.Type = null,
    block: ?*capella.BeaconBlock.Type = null,
    deposit: ?*capella.Deposit.Type = null,
    proposer_slashing: ?*capella.ProposerSlashing.Type = null,
    voluntary_exit: ?*capella.VoluntaryExit.Type = null,
    sync_aggregate: ?*capella.SyncAggregate.Type = null,
    body: ?*capella.BeaconBlockBody.Type = null,
    execution_payload: ?*capella.ExecutionPayload.Type = null,
    address_change: ?*capella.SignedBLSToExecutionChange.Type = null,
};

pub const DenebOperationsOut = struct {
    pre: ?*deneb.BeaconState.Type = null,
    post: ?*deneb.BeaconState.Type = null,
    attestation: ?*deneb.Attestation.Type = null,
    attester_slashing: ?*deneb.AttesterSlashing.Type = null,
    block: ?*deneb.BeaconBlock.Type = null,
    deposit: ?*deneb.Deposit.Type = null,
    proposer_slashing: ?*deneb.ProposerSlashing.Type = null,
    voluntary_exit: ?*deneb.VoluntaryExit.Type = null,
    sync_aggregate: ?*deneb.SyncAggregate.Type = null,
    body: ?*deneb.BeaconBlockBody.Type = null,
    execution_payload: ?*deneb.ExecutionPayload.Type = null,
    address_change: ?*deneb.SignedBLSToExecutionChange.Type = null,
};

pub const ElectraOperationsOut = struct {
    pre: ?*electra.BeaconState.Type = null,
    post: ?*electra.BeaconState.Type = null,
    attestation: ?*electra.Attestation.Type = null,
    attester_slashing: ?*electra.AttesterSlashing.Type = null,
    block: ?*electra.BeaconBlock.Type = null,
    deposit: ?*electra.Deposit.Type = null,
    proposer_slashing: ?*electra.ProposerSlashing.Type = null,
    voluntary_exit: ?*electra.VoluntaryExit.Type = null,
    sync_aggregate: ?*electra.SyncAggregate.Type = null,
    body: ?*electra.BeaconBlockBody.Type = null,
    execution_payload: ?*electra.ExecutionPayload.Type = null,
    address_change: ?*electra.SignedBLSToExecutionChange.Type = null,
    deposit_request: ?*electra.DepositRequest.Type = null,
    withdrawal_request: ?*electra.WithdrawalRequest.Type = null,
    consolidation_request: ?*electra.ConsolidationRequest.Type = null,
};
