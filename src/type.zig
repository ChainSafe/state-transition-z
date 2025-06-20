const std = @import("std");
const ssz = @import("consensus_types");
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
pub const ValidatorIndices = std.ArrayList(ValidatorIndex);
