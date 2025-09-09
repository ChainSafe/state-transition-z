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

pub fn runTestCase(fork: ForkSeq, handler: OperationsTestHandler, gpa: std.mem.Allocator, dir: std.fs.Dir) void {
    const test_case = switch (fork) {
        .phase0 => loadTestCase(Schema.Phase0Operations, dir, gpa),
        .altair => loadTestCase(Schema.AltairOperations, dir, gpa),
        .bellatrix => loadTestCase(Schema.BellatrixOperations, dir, gpa),
        .capella => loadTestCase(Schema.CapellaOperations, dir, gpa),
        .deneb => loadTestCase(Schema.DenebOperations, dir, gpa),
        .electra => loadTestCase(Schema.ElectraOperations, dir, gpa),
        else => loadTestCase(Schema.Phase0Operations, dir, gpa), // TODO: Handle this case
    };

    switch (handler) {
        .attestation => {
            // const preState = test_case.pre;
            // const expectedPostState = test_case.post;
            // const attestation = test_case.attestation;

            // const postState = processAttestations(gpa, preState, attestation);
        },
    }

    _ = test_case;
}
