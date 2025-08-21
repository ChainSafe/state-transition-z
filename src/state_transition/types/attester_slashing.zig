const ssz = @import("consensus_types");
const types = @import("../type.zig");
const IndexedAttestation = ssz.phase0.IndexedAttestation.Type;

pub const AttesterSlashings = union(enum) {
    // no need pointer because this is ArrayList already
    phase0: ssz.phase0.AttesterSlashings.Type,
    electra: ssz.electra.AttesterSlashings.Type,

    pub fn length(self: *const AttesterSlashings) usize {
        return switch (self.*) {
            inline .phase0, .electra => |attester_slashings| attester_slashings.items.len,
        };
    }

    pub fn items(self: *const AttesterSlashings) AttesterSlashingItems {
        return switch (self.*) {
            .phase0 => |attester_slashings| .{ .phase0 = attester_slashings.items },
            .electra => |attester_slashings| .{ .electra = attester_slashings.items },
        };
    }
};

pub const AttesterSlashingItems = union(enum) {
    phase0: []ssz.phase0.AttesterSlashing.Type,
    electra: []ssz.electra.AttesterSlashing.Type,
};

pub const AttesterSlashing = ssz.phase0.AttesterSlashing;
