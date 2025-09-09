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

pub fn runTestCase(fork: ForkSeq, handler: OperationsTestHandler, gpa: std.mem.Allocator, dir: std.fs.Dir) !void {
    switch (fork) {
        .phase0 => {
            const tc = try loadTestCase(Schema.Phase0Operations, Schema.Phase0OperationsOut, dir, gpa);
            _ = tc;
        },
        .altair => {
            const tc = try loadTestCase(Schema.AltairOperations, Schema.AltairOperationsOut, dir, gpa);
            _ = tc;
        },
        .bellatrix => {
            const tc = try loadTestCase(Schema.BellatrixOperations, Schema.BellatrixOperationsOut, dir, gpa);
            _ = tc;
        },
        .capella => {
            const tc = try loadTestCase(Schema.CapellaOperations, Schema.CapellaOperationsOut, dir, gpa);
            _ = tc;
        },
        .deneb => {
            const tc = try loadTestCase(Schema.DenebOperations, Schema.DenebOperationsOut, dir, gpa);
            _ = tc;
        },
        .electra => {
            const tc = try loadTestCase(Schema.ElectraOperations, Schema.ElectraOperationsOut, dir, gpa);
            _ = tc;
        },
    }

    switch (handler) {
        .attestation => {
            // const preState = test_case.pre;
            // const expectedPostState = test_case.post;
            // const attestation = test_case.attestation;

            // const postState = processAttestations(gpa, preState, attestation);
        },
        else => {
            // todo
        },
    }

    // _ = test_case;
}
