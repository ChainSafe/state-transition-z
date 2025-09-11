const std = @import("std");
const ssz = @import("consensus_types");

const state_transition = @import("state_transition");
const processAttestations = state_transition.processAttestations;
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const BeaconStateAllForks = state_transition.BeaconStateAllForks;
const Attestations = state_transition.Attestations;

const ForkSeq = @import("params").ForkSeq;
const OperationsTestHandler = @import("../test_type/handler.zig").OperationsTestHandler;
const Schema = @import("../test_type/schema/operations.zig");
const loadTestCase = @import("../test_case.zig").loadTestCase;
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
                        std.debug.print("name {s}\n", .{fld.name});
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
    _ = fork;
    switch (handler) {
        .attestation => {
            // These are mandatory fields
            const pre_state_altair: *ssz.altair.BeaconState.Type = test_case.pre.?;
            const attestation: *ssz.altair.Attestation.Type = test_case.attestation.?;

            // These may or may not exist
            const expected_post_state = test_case.post;

            const is_valid_test_case = test_case.post != null;

            _ = expected_post_state;
            _ = is_valid_test_case;

            const pre_state = try allocator.create(BeaconStateAllForks);
            pre_state.* = .{ .altair = pre_state_altair };

            var cached_pre_state = try TestCachedBeaconStateAllForks.initFromState(allocator, pre_state);
            defer cached_pre_state.deinit();

            var attestationArray: std.ArrayListUnmanaged(ssz.altair.Attestation.Type) = .empty;
            try attestationArray.append(allocator, attestation.*);
            const attestations = Attestations{ .phase0 = &attestationArray };

            const post_state = try processAttestations(allocator, cached_pre_state.cached_state, attestations, true);

            _ = post_state;
        },
        .attester_slashing => {},
        .block_header => {},
        .deposit => {},
        .proposer_slashing => {},
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
