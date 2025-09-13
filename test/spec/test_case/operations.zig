const std = @import("std");
const ssz = @import("consensus_types");

const state_transition = @import("state_transition");
const processAttestations = state_transition.processAttestations;
const processAttesterSlashing = state_transition.processAttesterSlashing;
const processProposerSlashing = state_transition.processProposerSlashing;
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const BeaconStateAllForks = state_transition.BeaconStateAllForks;
const Attestations = state_transition.Attestations;

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
    var pre_state = try BeaconStateAllForks.init(fork, pre_state_any);
    var cached_pre_state = try TestCachedBeaconStateAllForks.initFromState(allocator, &pre_state);
    defer cached_pre_state.deinit();

    switch (handler) {
        .attestation => {
            const expected_post_state_any = test_case.post;
            const attestation = test_case.attestation.?;

            if (@TypeOf(attestation.*) == ssz.electra.Attestations.Element.Type) {
                const ST = ssz.electra.Attestations;
                var arr = ST.default_value;
                defer arr.deinit(allocator);

                var attestation_clone: ST.Element.Type = undefined;
                try ST.Element.clone(allocator, attestation, &attestation_clone);

                try arr.append(allocator, attestation_clone);
                const attestations = Attestations{ .electra = &arr };
                try run_attestation_case(fork, allocator, cached_pre_state.cached_state, attestations, expected_post_state_any);
            } else {
                const ST = ssz.phase0.Attestations;
                var arr = ST.default_value;
                defer arr.deinit(allocator);

                var attestation_clone: ST.Element.Type = undefined;
                try ST.Element.clone(allocator, attestation, &attestation_clone);

                // try arr.append(allocator, @as(ssz.phase0.Attestations.Element.Type, attestation.*));
                try arr.append(allocator, attestation_clone);
                const attestations = Attestations{ .phase0 = &arr };
                try run_attestation_case(fork, allocator, cached_pre_state.cached_state, attestations, expected_post_state_any);
            }
        },
        .attester_slashing => {
            // These are mandatory fields
            const attester_slashing = test_case.attester_slashing.?;

            // These may or may not exist
            const expected_post_state_any = test_case.post; // null means invalid test case (expect error)
            const is_valid_test_case = expected_post_state_any != null;

            if (is_valid_test_case) {
                try processAttesterSlashing(ssz.phase0.AttesterSlashing.Type, allocator, cached_pre_state.cached_state, attester_slashing, true);
                const expected_post_state = try BeaconStateAllForks.init(fork, expected_post_state_any);

                try expectEqualBeaconStates(expected_post_state, cached_pre_state.cached_state.state.*);
            } else {
                if (processAttesterSlashing(ssz.phase0.AttesterSlashing.Type, allocator, cached_pre_state.cached_state, attester_slashing, true)) |_| {
                    return error.ExpectedFailure;
                } else |e| {
                    std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
                }
            }
        },
        .block_header => {},
        .deposit => {},
        .proposer_slashing => {
            // These are mandatory fields
            const proposer_slashing = test_case.proposer_slashing.?;

            // These may or may not exist
            const expected_post_state_any = test_case.post; // null means invalid test case (expect error)
            const is_valid_test_case = expected_post_state_any != null;

            if (is_valid_test_case) {
                try processProposerSlashing(cached_pre_state.cached_state, proposer_slashing, false);
                const expected_post_state = try BeaconStateAllForks.init(fork, expected_post_state_any);

                try expectEqualBeaconStates(expected_post_state, cached_pre_state.cached_state.state.*);
            } else {
                if (processProposerSlashing(cached_pre_state.cached_state, proposer_slashing, false)) |_| {
                    return error.ExpectedFailure;
                } else |e| {
                    std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
                }
            }
        },
        .voluntary_exit => {},
        .sync_aggregate => {},
        .execution_payload => {},
        .withdrawals => {},
        .bls_to_execution_change => {},
        .deposit_request => {},
        .withdrawal_request => {},
        .consolidation_request => {},
    }
}

// run_attester_slashing_case

fn run_attestation_case(
    fork: ForkSeq,
    allocator: std.mem.Allocator,
    cached_state: *state_transition.CachedBeaconStateAllForks,
    attestations: Attestations,
    expected_post_state_any: anytype,
) !void {
    const is_valid_test_case = expected_post_state_any != null;

    if (is_valid_test_case) {
        try processAttestations(allocator, cached_state, attestations, true);
        const expected_post_state = try BeaconStateAllForks.init(fork, expected_post_state_any);
        try expectEqualBeaconStates(expected_post_state, cached_state.state.*);
    } else {
        if (processAttestations(allocator, cached_state, attestations, true)) |_| {
            return error.ExpectedFailure;
        } else |e| {
            std.debug.print("make sure it failed with an expected reason: {any}\n", .{e});
        }
    }
}
