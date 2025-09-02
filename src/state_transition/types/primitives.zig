pub const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
pub const CommitteeIndex = ssz.primitive.CommitteeIndex.Type;
pub const WithdrawalCredentials = ssz.primitive.Root.Type;
pub const BLSPubkey = ssz.primitive.BLSPubkey.Type;
pub const Version = ssz.primitive.Version.Type;
pub const Epoch = ssz.primitive.Epoch.Type;
pub const SyncPeriod = ssz.primitive.SyncPeriod.Type;
pub const Root = ssz.primitive.Root.Type;
pub const Slot = ssz.primitive.Slot.Type;
pub const BLSSignature = ssz.primitive.BLSSignature.Type;
pub const Domain = ssz.primitive.Domain.Type;
pub const DomainType = ssz.primitive.DomainType.Type;
pub const ExecutionAddress = ssz.primitive.ExecutionAddress.Type;

pub const WithdrawalCredentialsLength = ssz.primitive.Root.length;

const std = @import("std");
const ssz = @import("consensus_types");
