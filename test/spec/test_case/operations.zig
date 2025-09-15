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

    switch (handler) {
        .attestation => {
            const attestation = test_case.attestation.?;

            if (@TypeOf(attestation.*) == ssz.electra.Attestations.Element.Type) {
                const ST = ssz.electra.Attestations;
                var arr = ST.default_value;
                defer arr.deinit(allocator);

                var attestation_clone: ST.Element.Type = undefined;
                try ST.Element.clone(allocator, attestation, &attestation_clone);

                try arr.append(allocator, attestation_clone);
                const attestations = Attestations{ .electra = &arr };
                try runAttestationCase(allocator, cached_pre_state.cached_state, attestations, expected_post_state_any);
            } else {
                const ST = ssz.phase0.Attestations;
                var arr = ST.default_value;
                defer arr.deinit(allocator);

                var attestation_clone: ST.Element.Type = undefined;
                try ST.Element.clone(allocator, attestation, &attestation_clone);

                try arr.append(allocator, attestation_clone);
                const attestations = Attestations{ .phase0 = &arr };
                try runAttestationCase(allocator, cached_pre_state.cached_state, attestations, expected_post_state_any);
            }
        },
        .attester_slashing => {
            const attester_slashing = test_case.attester_slashing.?;

            if (@TypeOf(attester_slashing.*) == ssz.electra.AttesterSlashing.Type) {
                try runAttesterSlashingCase(ssz.electra.AttesterSlashing.Type, allocator, cached_pre_state.cached_state, attester_slashing, expected_post_state_any);
            } else {
                try runAttesterSlashingCase(ssz.phase0.AttesterSlashing.Type, allocator, cached_pre_state.cached_state, attester_slashing, expected_post_state_any);
            }
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
            const is_valid_test_case = expected_post_state_any != null;

            if (is_valid_test_case) {
                try state_transition.processDeposit(allocator, cached_pre_state.cached_state, deposit);
                const expected_post_state = try BeaconStateAllForks.init(fork, expected_post_state_any);

                try expectEqualBeaconStates(expected_post_state, cached_pre_state.cached_state.state.*);
            } else {
                if (state_transition.processDeposit(allocator, cached_pre_state.cached_state, deposit)) |_| {
                    return error.ExpectedFailure;
                } else |e| {
                    std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
                }
            }
        },
        .proposer_slashing => {
            const proposer_slashing = test_case.proposer_slashing.?;
            const is_valid_test_case = expected_post_state_any != null;

            if (is_valid_test_case) {
                try state_transition.processProposerSlashing(cached_pre_state.cached_state, proposer_slashing, false);
                const expected_post_state = try BeaconStateAllForks.init(fork, expected_post_state_any);

                try expectEqualBeaconStates(expected_post_state, cached_pre_state.cached_state.state.*);
            } else {
                if (state_transition.processProposerSlashing(cached_pre_state.cached_state, proposer_slashing, false)) |_| {
                    return error.ExpectedFailure;
                } else |e| {
                    std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
                }
            }
        },
        .voluntary_exit => {
            const voluntary_exit = test_case.voluntary_exit.?;
            const is_valid_test_case = expected_post_state_any != null;

            if (is_valid_test_case) {
                try state_transition.processVoluntaryExit(cached_pre_state.cached_state, voluntary_exit, false);
                const expected_post_state = try BeaconStateAllForks.init(fork, expected_post_state_any);

                try expectEqualBeaconStates(expected_post_state, cached_pre_state.cached_state.state.*);
            } else {
                if (state_transition.processVoluntaryExit(cached_pre_state.cached_state, voluntary_exit, false)) |_| {
                    return error.ExpectedFailure;
                } else |e| {
                    std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
                }
            }
        },
        .sync_aggregate => {
            // TODO: processSyncAggregate currently takes block which is incorrect and not sync aggregate. Wait for it to accept sync aggregate.

            // if (comptime @hasField(@TypeOf(test_case), "sync_aggregate")) {
            //     const sync_aggregate = test_case.sync_aggregate.?;
            //     const is_valid_test_case = expected_post_state_any != null;

            //     if (is_valid_test_case) {
            //         try state_transition.processSyncAggregate(allocator, cached_pre_state.cached_state, sync_aggregate, false);
            //         const expected_post_state = try BeaconStateAllForks.init(fork, expected_post_state_any);

            //         try expectEqualBeaconStates(expected_post_state, cached_pre_state.cached_state.state.*);
            //     } else {
            //         if (state_transition.processSyncAggregate(allocator, cached_pre_state.cached_state, sync_aggregate, false)) |_| {
            //             return error.ExpectedFailure;
            //         } else |e| {
            //             std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
            //         }
            //     }
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

fn runAttestationCase(
    allocator: std.mem.Allocator,
    cached_state: *state_transition.CachedBeaconStateAllForks,
    attestations: Attestations,
    expected_post_state_any: anytype,
) !void {
    const is_valid_test_case = expected_post_state_any != null;

    if (is_valid_test_case) {
        try state_transition.processAttestations(allocator, cached_state, attestations, true);
        const expected_post_state = try BeaconStateAllForks.init(cached_state.state.forkSeq(), expected_post_state_any);
        try expectEqualBeaconStates(expected_post_state, cached_state.state.*);
    } else {
        if (state_transition.processAttestations(allocator, cached_state, attestations, true)) |_| {
            return error.ExpectedFailure;
        } else |e| {
            std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
        }
    }
}

fn runAttesterSlashingCase(
    comptime AS: type,
    allocator: std.mem.Allocator,
    cached_state: *state_transition.CachedBeaconStateAllForks,
    attester_slashing: *const AS,
    expected_post_state_any: anytype,
) !void {
    const is_valid_test_case = expected_post_state_any != null;

    if (is_valid_test_case) {
        try state_transition.processAttesterSlashing(AS, allocator, cached_state, attester_slashing, true);
        const expected_post_state = try BeaconStateAllForks.init(cached_state.state.forkSeq(), expected_post_state_any);

        try expectEqualBeaconStates(expected_post_state, cached_state.state.*);
    } else {
        if (state_transition.processAttesterSlashing(AS, allocator, cached_state, attester_slashing, true)) |_| {
            return error.ExpectedFailure;
        } else |e| {
            std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
        }
    }
}
