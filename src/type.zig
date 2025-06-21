const std = @import("std");
const ssz = @import("consensus_types");
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
pub const ValidatorIndices = std.ArrayList(ValidatorIndex);

pub fn cloneValidatorIndices(allocator: std.mem.Allocator, indices: ValidatorIndices) !ValidatorIndices {
    var cloned = try ValidatorIndices.initCapacity(allocator, indices.items.len);
    try cloned.appendSlice(indices.items);
    return cloned;
}
