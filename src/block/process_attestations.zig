const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const Epoch = ssz.primitive.Epoch.Type;
const preset = ssz.preset;
const params = @import("../params.zig");
const ForkSeq = @import("../config.zig").ForkSeq;
const Attestations = @import("../types/attestation.zig").Attestations;
const processAttestationPhase0 = @import("./process_attestation_phase0.zig").processAttestationPhase0;
const processAttestationsAltair = @import("./process_attestation_altair.zig").processAttestationsAltair;

pub fn processAttestations(allocator: Allocator, fork: ForkSeq, cached_state: *CachedBeaconStateAllForks, attestations: Attestations, verify_signatures: ?bool) !void {
    switch (attestations) {
        .phase0 => |attestations_phase0| {
            if (fork == ForkSeq.phase0) {
                for (attestations_phase0.items) |attestation| {
                    try processAttestationPhase0(cached_state, attestation, verify_signatures);
                }
            } else {
                // altair to deneb
                try processAttestationsAltair(allocator, fork, cached_state, ssz.phase0.Attestation.Type, attestations_phase0.items, verify_signatures);
            }
        },
        .electra => |attestations_electra| {
            try processAttestationsAltair(allocator, fork, cached_state, ssz.electra.Attestation.Type, attestations_electra.items, verify_signatures);
        },
    }
}

// TODO: unit tests
