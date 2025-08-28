pub const Block = union(enum) {
    regular: BeaconBlock,
    blinded: BlindedBeaconBlock,
};

pub const SignedBlock = union(enum) {
    regular: *const SignedBeaconBlock,
    blinded: *const SignedBlindedBeaconBlock,

    pub const BeaconBlockBody_ = union(enum) {
        regular: BeaconBlockBody,
        blinded: BlindedBeaconBlockBody,

        pub fn blobKzgCommitmentsLen(self: *const BeaconBlockBody_) usize {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getBlobKzgCommitments().items.len,
            };
        }

        pub fn getEth1Data(self: *const BeaconBlockBody_) *const ssz.phase0.Eth1Data.Type {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getEth1Data(),
            };
        }

        pub fn getRandaoReveal(self: *const BeaconBlockBody_) ssz.primitive.BLSSignature.Type {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getRandaoReveal(),
            };
        }

        pub fn deposits(self: *const BeaconBlockBody_) []Deposit {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getDeposits(),
            };
        }
        pub fn depositRequests(self: *const BeaconBlockBody_) []DepositRequest {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getDepositRequests(),
            };
        }
        pub fn withdrawalRequests(self: *const BeaconBlockBody_) []WithdrawalRequest {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getWithdrawalRequests(),
            };
        }
        pub fn consolidationRequests(self: *const BeaconBlockBody_) []ConsolidationRequest {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getConsolidationRequests(),
            };
        }

        pub fn syncAggregate(self: *const BeaconBlockBody_) *const ssz.altair.SyncAggregate.Type {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getSyncAggregate(),
            };
        }

        pub fn attesterSlashings(self: *const BeaconBlockBody_) AttesterSlashings {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getAttesterSlashings(),
            };
        }

        pub fn attestations(self: *const BeaconBlockBody_) Attestations {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getAttestations(),
            };
        }

        pub fn voluntaryExits(self: *const BeaconBlockBody_) []SignedVoluntaryExit {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getVoluntaryExits(),
            };
        }

        pub fn proposerSlashings(self: *const BeaconBlockBody_) []ProposerSlashing {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getProposerSlashings(),
            };
        }

        pub fn blsToExecutionChanges(self: *const BeaconBlockBody_) []SignedBLSToExecutionChange {
            return switch (self.*) {
                inline .regular, .blinded => |b| b.getBlsToExecutionChanges(),
            };
        }
    };

    pub fn getMessage(self: *const SignedBlock) Block {
        return switch (self.*) {
            .regular => |b| .{ .regular = b.getBeaconBlock() },
            .blinded => |b| .{ .blinded = b.getBeaconBlock() },
        };
    }
    pub fn getBeaconBlockBody(self: *const SignedBlock) BeaconBlockBody_ {
        return switch (self.*) {
            .regular => |b| .{ .regular = b.getBeaconBlock().getBeaconBlockBody() },
            .blinded => |b| .{ .blinded = b.getBeaconBlock().getBeaconBlockBody() },
        };
    }

    pub fn getParentRoot(self: *const SignedBlock) [32]u8 {
        return switch (self.*) {
            .regular => |b| b.getBeaconBlock().getParentRoot(),
            .blinded => |b| b.getBeaconBlock().getParentRoot(),
        };
    }

    pub fn getStateRoot(self: *const SignedBlock) [32]u8 {
        return switch (self.*) {
            .regular => |b| b.getBeaconBlock().getStateRoot(),
            .blinded => |b| b.getBeaconBlock().getStateRoot(),
        };
    }

    pub fn slot(self: *const SignedBlock) Slot {
        return switch (self.*) {
            .regular => |b| b.getBeaconBlock().slot(),
            .blinded => |b| b.getBeaconBlock().slot(),
        };
    }

    pub fn hashTreeRoot(self: *const SignedBlock, allocator: std.mem.Allocator, out: *[32]u8) !void {
        return switch (self.*) {
            .regular => |b| b.getBeaconBlock().hashTreeRoot(allocator, out),
            .blinded => |b| b.getBeaconBlock().hashTreeRoot(allocator, out),
        };
    }

    pub fn getProposerIndex(self: *const SignedBlock) u64 {
        return switch (self.*) {
            .regular => |b| b.getBeaconBlock().getProposerIndex(),
            .blinded => |b| b.getBeaconBlock().getProposerIndex(),
        };
    }

    pub fn getSignature(self: *const SignedBlock) ssz.primitive.BLSSignature.Type {
        return switch (self.*) {
            .regular => |b| b.getSignature(),
            .blinded => |b| b.getSignature(),
        };
    }
};

const std = @import("std");
const ssz = @import("consensus_types");
const preset = ssz.preset;
const ZERO_HASH = @import("../constants.zig").ZERO_HASH;

const Root = ssz.primitive.Root.Type;
const Deposit = ssz.phase0.Deposit.Type;
const DepositRequest = ssz.electra.DepositRequest.Type;
const WithdrawalRequest = ssz.electra.WithdrawalRequest.Type;
const ConsolidationRequest = ssz.electra.ConsolidationRequest.Type;

const Attestation = @import("types/attestation.zig").Attestation;
const Attestations = @import("types/attestation.zig").Attestations;
const AttesterSlashings = @import("types/attester_slashing.zig").AttesterSlashings;
const ProposerSlashing = ssz.phase0.ProposerSlashing.Type;
const SignedVoluntaryExit = ssz.phase0.SignedVoluntaryExit.Type;
const Slot = ssz.primitive.Slot.Type;
const SignedBLSToExecutionChange = ssz.capella.SignedBLSToExecutionChange.Type;

const BeaconBlock = @import("types/beacon_block.zig").BeaconBlock;
pub const SignedBeaconBlock = @import("types/beacon_block.zig").SignedBeaconBlock;
const SignedBlindedBeaconBlock = @import("types/beacon_block.zig").SignedBlindedBeaconBlock;
const BlindedBeaconBlock = @import("types/beacon_block.zig").BlindedBeaconBlock;
const BlindedBeaconBlockBody = @import("types/beacon_block.zig").BlindedBeaconBlockBody;
const BeaconBlockBody = @import("types/beacon_block.zig").BeaconBlockBody;
