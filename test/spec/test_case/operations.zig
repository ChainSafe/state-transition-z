const std = @import("std");
const ssz = @import("consensus_types");

const state_transition = @import("state_transition");
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const BeaconStateAllForks = state_transition.BeaconStateAllForks;
const Attestations = state_transition.Attestations;
const BeaconBlock = state_transition.BeaconBlock;

const ForkSeq = @import("params").ForkSeq;
const OperationsTestHandler = @import("../test_type/handler.zig").OperationsTestHandler;
const Schema = @import("../test_type/schema/operations.zig");
const expectEqualBeaconStates = @import("../test_case.zig").expectEqualBeaconStates;
const loadTestCase = @import("../test_case.zig").loadTestCase;
const isFixedType = @import("ssz").isFixedType;

const blst = @import("blst_min_pk");

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
    try blst.initializeThreadPool(allocator);
    defer blst.deinitializeThreadPool();

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
                .{ allocator, cached_pre_state.cached_state, attestations, true },
                cached_pre_state,
                maybe_expected_post_state,
            );
        },
        .attester_slashing => {
            const attester_slashing = test_case.attester_slashing.?;

            const ST = if (@TypeOf(attester_slashing.*) == ssz.electra.AttesterSlashing.Type) ssz.electra.AttesterSlashing.Type else ssz.phase0.AttesterSlashing;

            try runOperationCase(
                state_transition.processAttesterSlashing,
                .{ ST, allocator, cached_pre_state.cached_state, attester_slashing, true },
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
        .execution_payload => {},
        .withdrawals => {},
        .bls_to_execution_change => {},
        .deposit_request => {},
        .withdrawal_request => {},
        .consolidation_request => {},
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
