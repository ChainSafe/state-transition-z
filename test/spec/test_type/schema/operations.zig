const std = @import("std");
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

// Generate Out schema given an operation type.
// For each field, generate an out_field that has type of optional pointer of original field and has null as default value.
// eg. pre: ssz.phase0.BeaconState => pre: ?*ssz.phase0.BeaconState.Type = null
pub fn outType(comptime T: type) type {
    const fields = switch (@typeInfo(T)) {
        .@"struct" => |s| s.fields,
        else => @compileError("Expected a struct type."),
    };

    var out_fields: [fields.len]std.builtin.Type.StructField = undefined;

    inline for (fields, 0..) |fld, i| {
        comptime {
            if (!@hasDecl(fld.type, "Type"))
                @compileError("Field '" ++ fld.name ++ "' is not an SSZ schema meta. Missing .Type)");
        }

        // eg. fld.type is ssz.phase0.BeaconState, then OutFieldType = *?ssz.phase0.BeaconState.Type
        const OutFieldType = ?*fld.type.Type;

        comptime var default_null: OutFieldType = null;

        out_fields[i] = .{
            .name = fld.name,
            .type = OutFieldType,
            .default_value_ptr = @ptrCast(&default_null),
            .is_comptime = false,
            .alignment = 0,
        };
    }

    return @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .backing_integer = null,
            .fields = out_fields[0..],
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_tuple = false,
        },
    });
}

pub const Phase0OperationsOut = outType(Phase0Operations);
pub const AltairOperationsOut = outType(AltairOperations);
pub const BellatrixOperationsOut = outType(BellatrixOperations);
pub const CapellaOperationsOut = outType(CapellaOperations);
pub const DenebOperationsOut = outType(DenebOperations);
pub const ElectraOperationsOut = outType(ElectraOperations);
