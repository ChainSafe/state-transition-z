const std = @import("std");
const consensus_types = @import("consensus_types");
const phase0 = consensus_types.phase0;
const altair = consensus_types.altair;
const bellatrix = consensus_types.bellatrix;
const capella = consensus_types.capella;
const deneb = consensus_types.deneb;
const electra = consensus_types.electra;

const state_transition = @import("state_transition");
const processAttestations = state_transition.processAttestations;

const ForkSeq = @import("params").ForkSeq;
const OperationsTestHandler = @import("../test_type/handler.zig").OperationsTestHandler;
const Schema = @import("../test_type/schema/operations.zig");
const loadTestCase = @import("../test_case.zig").loadTestCase;
const isFixedType = @import("ssz").isFixedType;

pub fn runTestCase(fork: ForkSeq, handler: OperationsTestHandler, gpa: std.mem.Allocator, dir: std.fs.Dir) !void {
    switch (fork) {
        .phase0 => {
            const tc = try loadTestCase(Schema.Phase0Operations, Schema.Phase0OperationsOut, dir, gpa);

            defer {
                inline for (@typeInfo(Schema.Phase0Operations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(gpa, val_ptr);
                        }
                        gpa.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, gpa, tc);
        },
        .altair => {
            const tc = try loadTestCase(Schema.AltairOperations, Schema.AltairOperationsOut, dir, gpa);

            defer {
                inline for (@typeInfo(Schema.AltairOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        std.debug.print("name {s}\n", .{fld.name});
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(gpa, val_ptr);
                        }
                        gpa.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, gpa, tc);
        },
        .bellatrix => {
            const tc = try loadTestCase(Schema.BellatrixOperations, Schema.BellatrixOperationsOut, dir, gpa);

            defer {
                inline for (@typeInfo(Schema.BellatrixOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(gpa, val_ptr);
                        }
                        gpa.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, gpa, tc);
        },
        .capella => {
            const tc = try loadTestCase(Schema.CapellaOperations, Schema.CapellaOperationsOut, dir, gpa);

            defer {
                inline for (@typeInfo(Schema.CapellaOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(gpa, val_ptr);
                        }
                        gpa.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, gpa, tc);
        },
        .deneb => {
            const tc = try loadTestCase(Schema.DenebOperations, Schema.DenebOperationsOut, dir, gpa);

            defer {
                inline for (@typeInfo(Schema.DenebOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(gpa, val_ptr);
                        }
                        gpa.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, gpa, tc);
        },
        .electra => {
            const tc = try loadTestCase(Schema.ElectraOperations, Schema.ElectraOperationsOut, dir, gpa);

            defer {
                inline for (@typeInfo(Schema.ElectraOperations).@"struct".fields) |fld| {
                    const ST = fld.type;
                    if (@field(tc, fld.name)) |val_ptr| {
                        if (@hasDecl(ST, "deinit")) {
                            ST.deinit(gpa, val_ptr);
                        }
                        gpa.destroy(val_ptr);
                    }
                }
            }
            try processTestCase(fork, handler, gpa, tc);
        },
    }
}

fn processTestCase(fork: ForkSeq, handler: OperationsTestHandler, gpa: std.mem.Allocator, test_case: anytype) !void {
    _ = gpa;
    _ = fork;
    switch (handler) {
        .attestation => {
            const preState = test_case.pre.?;
            const expectedPostState = test_case.post.?;
            const attestation = test_case.attestation.?;

            _ = preState;
            _ = expectedPostState;
            _ = attestation;

            // const postState = processAttestations(gpa, preState, attestation);
        },
        else => {
            // todo
        },
    }
}
