const std = @import("std");
const ssz = @import("consensus_types");
const preset = @import("preset").preset;
const c = @import("constants");
const digest = @import("./sha256.zig").digest;
const BLSSignature = ssz.primitive.BLSSignature.Type;
const ZERO_BIGINT = 0;

pub fn isSyncCommitteeAggregator(selection_proof: BLSSignature) bool {
    const module = @max(1, @divFloor(@divFloor(preset.SYNC_COMMITTEE_SIZE, params.SYNC_COMMITTEE_SUBNET_COUNT), params.TARGET_AGGREGATORS_PER_SYNC_SUBCOMMITTEE));
    const module = @max(1, @divFloor(@divFloor(preset.SYNC_COMMITTEE_SIZE, c.SYNC_COMMITTEE_SUBNET_COUNT), c.TARGET_AGGREGATORS_PER_SYNC_SUBCOMMITTEE));
    return isSelectionProofValid(selection_proof, module);
}

pub fn isAggregatorFromCommitteeLength(committee_len: usize, slot_signature: BLSSignature) bool {
    const module = @max(1, @divFloor(committee_len, c.TARGET_AGGREGATORS_PER_SYNC_SUBCOMMITTEE));
    return isSelectionProofValid(slot_signature, module);
}

pub fn isSelectionProofValid(sig: BLSSignature, modulo: u64) bool {
    var root: [32]u8 = undefined;
    digest(sig.toBytes(), &root);
    const value = std.mem.readInt(u64, root[0..8], .little);
    return (value % modulo) == ZERO_BIGINT;
}
