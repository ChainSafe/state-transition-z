const std = @import("std");
const ssz = @import("consensus_types");
pub const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
pub const ValidatorIndices = std.ArrayList(ValidatorIndex);
pub const WithdrawalCredentials = ssz.primitive.Root.Type;
pub const Epoch = ssz.primitive.Epoch.Type;
pub const PendingDeposit = ssz.electra.PendingDeposit.Type;
pub const BLSPubkey = ssz.primitive.BLSPubkey.Type;
pub const ForkSeq = @import("./config.zig").ForkSeq;

pub fn cloneValidatorIndices(allocator: std.mem.Allocator, indices: ValidatorIndices) !ValidatorIndices {
    var cloned = try ValidatorIndices.initCapacity(allocator, indices.items.len);
    try cloned.appendSlice(indices.items);
    return cloned;
}
