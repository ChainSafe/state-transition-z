const std = @import("std");
const ssz = @import("consensus_types");
pub const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
pub const ValidatorIndices = std.ArrayList(ValidatorIndex);
pub const WithdrawalCredentials = ssz.primitive.Root.Type;
pub const BLSPubkey = ssz.primitive.BLSPubkey.Type;
pub const Version = ssz.primitive.Version.Type;
pub const DomainType = ssz.primitive.DomainType.Type;
pub const Epoch = ssz.primitive.Epoch.Type;
pub const Root = ssz.primitive.Root.Type;
pub const Slot = ssz.primitive.Slot.Type;
pub const BLSSignature = ssz.primitive.BLSSignature.Type;
pub const Domain = ssz.primitive.Domain.Type;

pub const SigningData = ssz.phase0.SigningData.Type;
pub const DepositMessage = ssz.phase0.DepositMessage.Type;
pub const Phase0Deposit = ssz.phase0.Deposit.Type;
pub const BeaconBlockHeader = ssz.phase0.BeaconBlockHeader.Type;

pub const PendingDeposit = ssz.electra.PendingDeposit.Type;
pub const ForkSeq = @import("./config.zig").ForkSeq;
pub const Fork = ssz.phase0.Fork.Type;

pub fn cloneValidatorIndices(allocator: std.mem.Allocator, indices: ValidatorIndices) !ValidatorIndices {
    var cloned = try ValidatorIndices.initCapacity(allocator, indices.items.len);
    try cloned.appendSlice(indices.items);
    return cloned;
}
