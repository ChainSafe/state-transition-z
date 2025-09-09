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
    attestation: ?phase0.Attestation,
    attester_slashing: ?phase0.AttesterSlashing,
    block: ?phase0.BeaconBlock,
    deposit: ?phase0.Deposit,
    proposer_slashing: ?phase0.ProposerSlashing,
    voluntary_exit: ?phase0.VoluntaryExit,
};

pub const AltairOperations = struct {
    pre: altair.BeaconState,
    post: altair.BeaconState,
    attestation: ?altair.Attestation,
    attester_slashing: ?altair.AttesterSlashing,
    block: ?altair.BeaconBlock,
    deposit: ?altair.Deposit,
    proposer_slashing: ?altair.ProposerSlashing,
    voluntary_exit: ?altair.VoluntaryExit,
    sync_aggregate: ?altair.SyncAggregate,
};

pub const BellatrixOperations = struct {
    pre: bellatrix.BeaconState,
    post: bellatrix.BeaconState,
    attestation: ?bellatrix.Attestation,
    attester_slashing: ?bellatrix.AttesterSlashing,
    block: ?bellatrix.BeaconBlock,
    deposit: ?bellatrix.Deposit,
    proposer_slashing: ?bellatrix.ProposerSlashing,
    voluntary_exit: ?bellatrix.VoluntaryExit,
    sync_aggregate: ?bellatrix.SyncAggregate,
    body: ?bellatrix.BeaconBlockBody,
};

pub const CapellaOperations = struct {
    pre: capella.BeaconState,
    post: capella.BeaconState,
    attestation: ?capella.Attestation,
    attester_slashing: ?capella.AttesterSlashing,
    block: ?capella.BeaconBlock,
    deposit: ?capella.Deposit,
    proposer_slashing: ?capella.ProposerSlashing,
    voluntary_exit: ?capella.VoluntaryExit,
    sync_aggregate: ?capella.SyncAggregate,
    body: ?capella.BeaconBlockBody,
    execution_payload: ?capella.ExecutionPayload,
    address_change: ?capella.SignedBLSToExecutionChange,
};

pub const DenebOperations = struct {
    pre: deneb.BeaconState,
    post: deneb.BeaconState,
    attestation: ?deneb.Attestation,
    attester_slashing: ?deneb.AttesterSlashing,
    block: ?deneb.BeaconBlock,
    deposit: ?deneb.Deposit,
    proposer_slashing: ?deneb.ProposerSlashing,
    voluntary_exit: ?deneb.VoluntaryExit,
    sync_aggregate: ?deneb.SyncAggregate,
    body: ?deneb.BeaconBlockBody,
    execution_payload: ?deneb.ExecutionPayload,
    address_change: ?deneb.SignedBLSToExecutionChange,
};

pub const ElectraOperations = struct {
    pre: electra.BeaconState,
    post: electra.BeaconState,
    attestation: ?electra.Attestation,
    attester_slashing: ?electra.AttesterSlashing,
    block: ?electra.BeaconBlock,
    deposit: ?electra.Deposit,
    proposer_slashing: ?electra.ProposerSlashing,
    voluntary_exit: ?electra.VoluntaryExit,
    sync_aggregate: ?electra.SyncAggregate,
    body: ?electra.BeaconBlockBody,
    execution_payload: ?electra.ExecutionPayload,
    address_change: ?electra.SignedBLSToExecutionChange,
    deposit_request: ?electra.DepositRequest,
    withdrawal_request: ?electra.WithdrawalRequest,
    consolidation_request: ?electra.ConsolidationRequest,
};
