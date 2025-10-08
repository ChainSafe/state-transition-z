const std = @import("std");
const preset = @import("preset").preset;
const ssz = @import("consensus_types");

const state_transition = @import("state_transition");
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const BeaconStateAllForks = state_transition.BeaconStateAllForks;
const Attestations = state_transition.Attestations;
const BeaconBlock = state_transition.BeaconBlock;
const SignedBlock = state_transition.SignedBlock;
const BlockExternalData = state_transition.state_transition.BlockExternalData;
const WithdrawalsResult = state_transition.WithdrawalsResult;

const ForkSeq = @import("config").ForkSeq;
const OperationsTestHandler = @import("../test_type/handler.zig").OperationsTestHandler;
const Schema = @import("../test_type/schema/operations.zig");
const expectEqualBeaconStates = @import("../test_case.zig").expectEqualBeaconStates;
const loadTestCase = @import("../test_case.zig").loadTestCase;
const Withdrawals = ssz.capella.Withdrawals.Type;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const isFixedType = @import("ssz").isFixedType;

pub fn runTestCase(fork: ForkSeq, handler: OperationsTestHandler, allocator: std.mem.Allocator, dir: std.fs.Dir) !void {
    switch (fork) {
        .phase0 => {
            const tc = try loadTestCase(Schema.Phase0Operations, Schema.Phase0OperationsOut, dir, allocator);

            defer {
                inline for (@typeInfo(Schema.Phase0Operations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(allocator, val_ptr);
                        }
                        allocator.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, allocator, tc);
        },
        .altair => {
            const tc = try loadTestCase(Schema.AltairOperations, Schema.AltairOperationsOut, dir, allocator);

            defer {
                inline for (@typeInfo(Schema.AltairOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(allocator, val_ptr);
                        }
                        allocator.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, allocator, tc);
        },
        .bellatrix => {
            const tc = try loadTestCase(Schema.BellatrixOperations, Schema.BellatrixOperationsOut, dir, allocator);

            defer {
                inline for (@typeInfo(Schema.BellatrixOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(allocator, val_ptr);
                        }
                        allocator.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, allocator, tc);
        },
        .capella => {
            const tc = try loadTestCase(Schema.CapellaOperations, Schema.CapellaOperationsOut, dir, allocator);

            defer {
                inline for (@typeInfo(Schema.CapellaOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(allocator, val_ptr);
                        }
                        allocator.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, allocator, tc);
        },
        .deneb => {
            const tc = try loadTestCase(Schema.DenebOperations, Schema.DenebOperationsOut, dir, allocator);

            defer {
                inline for (@typeInfo(Schema.DenebOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(allocator, val_ptr);
                        }
                        allocator.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, allocator, tc);
        },
        .electra => {
            const tc = try loadTestCase(Schema.ElectraOperations, Schema.ElectraOperationsOut, dir, allocator);

            defer {
                inline for (@typeInfo(Schema.ElectraOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(allocator, val_ptr);
                        }
                        allocator.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, allocator, tc);
        },
    }
}

fn processTestCase(fork: ForkSeq, handler: OperationsTestHandler, allocator: std.mem.Allocator, test_case: anytype) !void {
    const pre_state_any = test_case.pre.?;
    const expected_post_state_any = test_case.post;

    var pre_state = try BeaconStateAllForks.init(fork, pre_state_any);
    var cached_pre_state = try TestCachedBeaconStateAllForks.initFromState(allocator, &pre_state);
    defer cached_pre_state.deinit();

    const maybe_expected_post_state = if (expected_post_state_any) |s| try BeaconStateAllForks.init(fork, s) else null;

    switch (handler) {
        .attestation => {
            const attestation = test_case.attestation.?;

            const ST = if (@TypeOf(attestation.*) == ssz.electra.Attestations.Element.Type) ssz.electra.Attestations else ssz.phase0.Attestations;

            var arr = ST.default_value;
            defer arr.deinit(allocator);

            var attestation_clone: ST.Element.Type = undefined;
            try ST.Element.clone(allocator, attestation, &attestation_clone);

            try arr.append(allocator, attestation_clone);

            const attestations = if (@TypeOf(attestation.*) == ssz.electra.Attestations.Element.Type)
                Attestations{ .electra = &arr }
            else
                Attestations{ .phase0 = &arr };

            try runOperationCase(
                state_transition.processAttestations,
                .{ allocator, cached_pre_state.cached_state, attestations, false },
                cached_pre_state,
                maybe_expected_post_state,
            );
        },
        .attester_slashing => {
            const attester_slashing = test_case.attester_slashing.?;

            const ST = if (@TypeOf(attester_slashing.*) == ssz.electra.AttesterSlashing.Type) ssz.electra.AttesterSlashing.Type else ssz.phase0.AttesterSlashing;

            try runOperationCase(
                state_transition.processAttesterSlashing,
                .{ ST, cached_pre_state.cached_state, attester_slashing, false },
                cached_pre_state,
                maybe_expected_post_state,
            );
        },
        .block_header => {
            const block = test_case.block.?;

            const beacon_block: BeaconBlock = switch (@TypeOf(block.*)) {
                ssz.phase0.BeaconBlock.Type => BeaconBlock{ .phase0 = block },
                ssz.altair.BeaconBlock.Type => BeaconBlock{ .altair = block },
                ssz.bellatrix.BeaconBlock.Type => BeaconBlock{ .bellatrix = block },
                ssz.capella.BeaconBlock.Type => BeaconBlock{ .capella = block },
                ssz.deneb.BeaconBlock.Type => BeaconBlock{ .deneb = block },
                ssz.electra.BeaconBlock.Type => BeaconBlock{ .electra = block },
                else => @panic("unsupported block type"),
            };

            // TODO: processBlockHeader currently takes signed block which is incorrect. Wait for it to accept unsigned block.
            _ = beacon_block;

            // const is_valid_test_case = expected_post_state_any != null;

            // if (is_valid_test_case) {
            //     try processBlockHeader(allocator, cached_state, block);
            //     const expected_post_state = try BeaconStateAllForks.init(cached_state.state.forkSeq(), expected_post_state_any);
            //     try expectEqualBeaconStates(expected_post_state, cached_state.state.*);
            // } else {
            //     if (processBlockHeader(allocator, cached_state, block)) |_| {
            //         return error.ExpectedFailure;
            //     } else |e| {
            //         std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
            //     }
            // }
        },
        .deposit => {
            const deposit = test_case.deposit.?;

            try runOperationCase(
                state_transition.processDeposit,
                .{ allocator, cached_pre_state.cached_state, deposit },
                cached_pre_state,
                maybe_expected_post_state,
            );
        },
        .proposer_slashing => {
            const proposer_slashing = test_case.proposer_slashing.?;

            try runOperationCase(
                state_transition.processProposerSlashing,
                .{ cached_pre_state.cached_state, proposer_slashing, false },
                cached_pre_state,
                maybe_expected_post_state,
            );
        },
        .voluntary_exit => {
            const voluntary_exit = test_case.voluntary_exit.?;

            try runOperationCase(
                state_transition.processVoluntaryExit,
                .{ cached_pre_state.cached_state, voluntary_exit, false },
                cached_pre_state,
                maybe_expected_post_state,
            );
        },
        .sync_aggregate => {
            // TODO: processSyncAggregate currently takes block which is incorrect and not sync aggregate. Wait for it to accept sync aggregate.

            // if (comptime @hasField(@TypeOf(test_case), "sync_aggregate")) {
            //     const sync_aggregate = test_case.sync_aggregate.?;
            //     const is_valid_test_case = expected_post_state_any != null;

            //     try runOperationCase(
            //         state_transition.processSyncAggregate,
            //         .{ allocator, cached_pre_state.cached_state, sync_aggregate, false },
            //         is_valid_test_case,
            //         expected_post_state_any,
            //         fork,
            //         &cached_pre_state,
            //     );
            // } else {
            //     @panic("sync_aggregate field not found in test case");
            // }
        },
        .execution_payload => {
            if (comptime @hasField(@TypeOf(test_case), "body")) {
                const body = test_case.body.?;
                const beacon_block_body: SignedBlock.Body = switch (@TypeOf(body.*)) {
                    ssz.bellatrix.BeaconBlockBody.Type => SignedBlock.Body{ .regular = .{ .bellatrix = body } },
                    ssz.capella.BeaconBlockBody.Type => SignedBlock.Body{ .regular = .{ .capella = body } },
                    ssz.deneb.BeaconBlockBody.Type => SignedBlock.Body{ .regular = .{ .deneb = body } },
                    ssz.electra.BeaconBlockBody.Type => SignedBlock.Body{ .regular = .{ .electra = body } },
                    else => @panic("unsupported block body type"),
                };

                try runOperationCase(
                    state_transition.processExecutionPayload,
                    .{ allocator, cached_pre_state.cached_state, beacon_block_body, BlockExternalData{ .execution_payload_status = .valid, .data_availability_status = .available } },
                    cached_pre_state,
                    maybe_expected_post_state,
                );
            } else {
                @panic("block body not found in execution_payload test");
            }
        },
        .withdrawals => {
            if (comptime @hasField(@TypeOf(test_case), "execution_payload")) {
                var withdrawals_result = WithdrawalsResult{ .withdrawals = try Withdrawals.initCapacity(
                    allocator,
                    preset.MAX_WITHDRAWALS_PER_PAYLOAD,
                ) };

                var withdrawal_balances = std.AutoHashMap(ValidatorIndex, usize).init(allocator);
                defer withdrawal_balances.deinit();

                try state_transition.getExpectedWithdrawals(allocator, &withdrawals_result, &withdrawal_balances, cached_pre_state.cached_state);
                defer withdrawals_result.withdrawals.deinit(allocator);

                try runOperationCase(
                    state_transition.processWithdrawals,
                    .{ cached_pre_state.cached_state, withdrawals_result },
                    cached_pre_state,
                    maybe_expected_post_state,
                );
            } else {
                @panic("execution payload not found in withdrawals test");
            }
        },
        .bls_to_execution_change => {
            if (comptime @hasField(@TypeOf(test_case), "address_change")) {
                const signed_bls_to_execution_change = test_case.address_change.?;

                try runOperationCase(
                    state_transition.processBlsToExecutionChange,
                    .{ cached_pre_state.cached_state, signed_bls_to_execution_change },
                    cached_pre_state,
                    maybe_expected_post_state,
                );
            } else {
                @panic("address change not found in bls_to_execution_change test");
            }
        },
        .deposit_request => {
            if (comptime @hasField(@TypeOf(test_case), "deposit_request")) {
                const deposit_request = test_case.deposit_request.?;

                try runOperationCase(
                    state_transition.processDepositRequest,
                    .{ allocator, cached_pre_state.cached_state, deposit_request },
                    cached_pre_state,
                    maybe_expected_post_state,
                );
            } else {
                @panic("deposit request not found in depost_request test");
            }
        },
        .withdrawal_request => {
            if (comptime @hasField(@TypeOf(test_case), "withdrawal_request")) {
                const withdrawal_request = test_case.withdrawal_request.?;

                try runOperationCase(
                    state_transition.processWithdrawalRequest,
                    .{ allocator, cached_pre_state.cached_state, withdrawal_request },
                    cached_pre_state,
                    maybe_expected_post_state,
                );
            } else {
                @panic("withdrawal request not found in withdrawal_request test");
            }
        },
        .consolidation_request => {
            if (comptime @hasField(@TypeOf(test_case), "consolidation_request")) {
                const consolidation_request = test_case.consolidation_request.?;

                try runOperationCase(
                    state_transition.processConsolidationRequest,
                    .{ allocator, cached_pre_state.cached_state, consolidation_request },
                    cached_pre_state,
                    maybe_expected_post_state,
                );
            } else {
                @panic("consolidation request not found in consolidation_request test");
            }
        },
    }
}

fn runOperationCase(
    comptime Fn: anytype,
    args: anytype,
    cached_pre_state: TestCachedBeaconStateAllForks,
    maybe_expected_post_state: ?BeaconStateAllForks,
) !void {
    const call_result = @call(.auto, Fn, args);

    // If post state is provided, the operation is expected to succeed and the resulting state should match.
    if (maybe_expected_post_state) |expected_post_state| {
        try call_result;
        try expectEqualBeaconStates(expected_post_state, cached_pre_state.cached_state.state.*);
    } else {
        if (call_result) |_| {
            return error.ExpectedFailure;
        } else |e| {
            std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
        }
    }
}
