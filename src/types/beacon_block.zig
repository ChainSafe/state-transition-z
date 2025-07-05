const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const ssz = @import("consensus_types");
const types = @import("../type.zig");
const Slot = types.Slot;
const ValidatorIndex = types.ValidatorIndex;
const Root = types.Root;
const ExecutionPayload = @import("./execution_payload.zig").ExecutionPayload;
const Attestations = @import("./attestation.zig").Attestations;

pub const SignedBeaconBlock = union(enum) {
    phase0: *const ssz.phase0.SignedBeaconBlock.Type,
    altair: *const ssz.altair.SignedBeaconBlock.Type,
    bellatrix: *const ssz.bellatrix.SignedBeaconBlock.Type,
    capella: *const ssz.capella.SignedBeaconBlock.Type,
    deneb: *const ssz.deneb.SignedBeaconBlock.Type,
    electra: *const ssz.electra.SignedBeaconBlock.Type,

    pub fn getBeaconBlock(self: *const SignedBeaconBlock) BeaconBlock {
        return switch (self.*) {
            .phase0 => |block| .{ .phase0 = &block.message },
            .altair => |block| .{ .altair = &block.message },
            .bellatrix => |block| .{ .bellatrix = &block.message },
            .capella => |block| .{ .capella = &block.message },
            .deneb => |block| .{ .deneb = &block.message },
            .electra => |block| .{ .electra = &block.message },
        };
    }
};

// TODO: also model BlindedBeaconBlock in this enum?

pub const BeaconBlock = union(enum) {
    phase0: *const ssz.phase0.BeaconBlock.Type,
    altair: *const ssz.altair.BeaconBlock.Type,
    bellatrix: *const ssz.bellatrix.BeaconBlock.Type,
    capella: *const ssz.capella.BeaconBlock.Type,
    deneb: *const ssz.deneb.BeaconBlock.Type,
    electra: *const ssz.electra.BeaconBlock.Type,

    pub fn hashTreeRoot(self: *const BeaconBlock, allocator: std.mem.Allocator, out: *[32]u8) !void {
        switch (self.*) {
            .phase0 => |block| try ssz.phase0.BeaconBlock.hashTreeRoot(allocator, block, out),
            .altair => |block| try ssz.altair.BeaconBlock.hashTreeRoot(allocator, block, out),
            .bellatrix => |block| try ssz.bellatrix.BeaconBlock.hashTreeRoot(allocator, block, out),
            .capella => |block| try ssz.capella.BeaconBlock.hashTreeRoot(allocator, block, out),
            .deneb => |block| try ssz.deneb.BeaconBlock.hashTreeRoot(allocator, block, out),
            .electra => |block| try ssz.electra.BeaconBlock.hashTreeRoot(allocator, block, out),
        }
    }

    pub fn getSlot(self: *const BeaconBlock) Slot {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |block| block.slot,
        };
    }

    pub fn getProposerIndex(self: *const BeaconBlock) ValidatorIndex {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |block| block.proposer_index,
        };
    }

    pub fn getParentRoot(self: *const BeaconBlock) Root {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |block| block.parent_root,
        };
    }

    pub fn getStateRoot(self: *const BeaconBlock) Root {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |block| block.state_root,
        };
    }

    pub fn getBeaconBlockBody(self: *const BeaconBlock) BeaconBlockBody {
        return switch (self.*) {
            .phase0 => |block| .{ .phase0 = &block.body },
            .altair => |block| .{ .altair = &block.body },
            .bellatrix => |block| .{ .bellatrix = &block.body },
            .capella => |block| .{ .capella = &block.body },
            .deneb => |block| .{ .deneb = &block.body },
            .electra => |block| .{ .electra = &block.body },
        };
    }
};

pub const BeaconBlockBody = union(enum) {
    phase0: *const ssz.phase0.BeaconBlockBody.Type,
    altair: *const ssz.altair.BeaconBlockBody.Type,
    bellatrix: *const ssz.bellatrix.BeaconBlockBody.Type,
    capella: *const ssz.capella.BeaconBlockBody.Type,
    deneb: *const ssz.deneb.BeaconBlockBody.Type,
    electra: *const ssz.electra.BeaconBlockBody.Type,

    pub fn hashTreeRoot(self: *const BeaconBlockBody, allocator: std.mem.Allocator, out: *[32]u8) !void {
        return switch (self.*) {
            .phase0 => |body| try ssz.phase0.BeaconBlockBody.hashTreeRoot(allocator, body, out),
            .altair => |body| try ssz.altair.BeaconBlockBody.hashTreeRoot(allocator, body, out),
            .bellatrix => |body| try ssz.bellatrix.BeaconBlockBody.hashTreeRoot(allocator, body, out),
            .capella => |body| try ssz.capella.BeaconBlockBody.hashTreeRoot(allocator, body, out),
            .deneb => |body| try ssz.deneb.BeaconBlockBody.hashTreeRoot(allocator, body, out),
            .electra => |body| try ssz.electra.BeaconBlockBody.hashTreeRoot(allocator, body, out),
        };
    }

    pub fn isExecutionType(self: *const BeaconBlockBody) bool {
        return switch (self.*) {
            .phase0 => false,
            .altair => false,
            else => true,
        };
    }

    // phase0 fields
    pub fn getRandaoReveal(self: *const BeaconBlockBody) ssz.primitive.BLSSignature.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| body.randao_reveal,
        };
    }

    pub fn getEth1Data(self: *const BeaconBlockBody) *const ssz.phase0.Eth1Data.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| &body.eth1_data,
        };
    }

    pub fn getGraffity(self: *const BeaconBlockBody) ssz.primitive.Bytes32.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| body.graffiti,
        };
    }

    pub fn getProposerSlashings(self: *const BeaconBlockBody) *const ssz.phase0.ProposerSlashings.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| &body.proposer_slashings,
        };
    }

    pub fn getAttesterSlashings(self: *const BeaconBlockBody) *const ssz.phase0.AttesterSlashings.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| &body.attester_slashings,
        };
    }

    pub fn getAttestations(self: *const BeaconBlockBody) Attestations {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb => |body| .{ .phase0 = &body.attestations },
            .electra => |body| .{ .electra = &body.attestations },
        };
    }

    pub fn getDeposits(self: *const BeaconBlockBody) *const ssz.phase0.Deposits.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| &body.deposits,
        };
    }

    pub fn getVoluntaryExits(self: *const BeaconBlockBody) *const ssz.phase0.VoluntaryExits.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| &body.voluntary_exits,
        };
    }

    // altair fields
    pub fn getSyncAggregate(self: *const BeaconBlockBody) *const ssz.altair.SyncAggregate.Type {
        return switch (self.*) {
            inline .altair, .bellatrix, .capella, .deneb, .electra => |body| &body.sync_aggregate,
            else => @panic("SyncAggregate is not available in phase0"),
        };
    }

    // bellatrix fields
    pub fn getExecutionPayload(self: *const BeaconBlockBody) ExecutionPayload {
        return switch (self.*) {
            inline .phase0, .altair => @panic("ExecutionPayload is not available in phase0 or altair"),
            .bellatrix => |body| .{ .bellatrix = &body.execution_payload },
            .capella => |body| .{ .capella = &body.execution_payload },
            .deneb => |body| .{ .deneb = &body.execution_payload },
            .electra => |body| .{ .electra = &body.execution_payload },
        };
    }

    // capella fields
    pub fn getBlsToExecutionChanges(self: *const BeaconBlockBody) *const ssz.capella.SignedBLSToExecutionChanges.Type {
        return switch (self.*) {
            .phase0,
            => @panic("BlsToExecutionChanges is not available in phase0"),
            .altair => @panic("BlsToExecutionChanges is not available in altair"),
            .bellatrix => @panic("BlsToExecutionChanges is not available in bellatrix"),
            .capella => |body| &body.bls_to_execution_changes,
            .deneb => |body| &body.bls_to_execution_changes,
            .electra => |body| &body.bls_to_execution_changes,
        };
    }

    // deneb fields
    pub fn getBlobKzgCommitments(self: *const BeaconBlockBody) *const ssz.deneb.BlobKzgCommitments.Type {
        return switch (self.*) {
            .phase0 => @panic("BlobKzgCommitments is not available in phase0"),
            .altair => @panic("BlobKzgCommitments is not available in altair"),
            .bellatrix => @panic("BlobKzgCommitments is not available in bellatrix"),
            .capella => @panic("BlobKzgCommitments is not available in capella"),
            .deneb => |body| &body.blob_kzg_commitments,
            .electra => |body| &body.blob_kzg_commitments,
        };
    }

    // electra fields
    pub fn getExecutionRequests(self: *const BeaconBlockBody) *const ssz.electra.ExecutionRequests.Type {
        return switch (self.*) {
            .phase0 => @panic("ExecutionRequests is not available in phase0"),
            .altair => @panic("ExecutionRequests is not available in altair"),
            .bellatrix => @panic("ExecutionRequests is not available in bellatrix"),
            .capella => @panic("ExecutionRequests is not available in capella"),
            .deneb => @panic("ExecutionRequests is not available in deneb"),
            .electra => |body| &body.execution_requests,
        };
    }
};

test "electra - sanity" {
    const allocator = std.testing.allocator;
    var electra_block = ssz.electra.BeaconBlock.default_value;
    electra_block.slot = 12345;
    electra_block.proposer_index = 1;
    electra_block.body.randao_reveal = [_]u8{1} ** 96;
    var attestations = try std.ArrayListUnmanaged(ssz.electra.Attestation.Type).initCapacity(std.testing.allocator, 10);
    defer attestations.deinit(allocator);
    var attestation0 = ssz.electra.Attestation.default_value;
    attestation0.data.slot = 12345;
    try attestations.append(allocator, attestation0);
    electra_block.body.attestations = attestations;
    try expect(electra_block.body.attestations.items[0].data.slot == 12345);
    const beacon_block = BeaconBlock{ .electra = &electra_block };

    try expect(beacon_block.getSlot() == 12345);
    try expect(beacon_block.getProposerIndex() == 1);
    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 32, &beacon_block.getParentRoot());
    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 32, &beacon_block.getStateRoot());

    var out: [32]u8 = undefined;
    // all phases
    try beacon_block.hashTreeRoot(allocator, &out);
    try expect(!std.mem.eql(u8, &[_]u8{0} ** 32, &out));
    const block_body = beacon_block.getBeaconBlockBody();
    out = [_]u8{0} ** 32;
    try block_body.hashTreeRoot(allocator, &out);
    try expect(!std.mem.eql(u8, &[_]u8{0} ** 32, &out));

    try std.testing.expectEqualSlices(u8, &[_]u8{1} ** 96, &block_body.getRandaoReveal());
    const eth1_data = block_body.getEth1Data();
    try expect(eth1_data.deposit_count == 0);
    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 32, &block_body.getGraffity());
    try expect(block_body.getProposerSlashings().items.len == 0);
    try expect(block_body.getAttesterSlashings().items.len == 0);
    try expect(block_body.getAttestations().length() == 1);
    try expect(block_body.getAttestations().items().electra[0].data.slot == 12345);
    try expect(block_body.getDeposits().items.len == 0);
    try expect(block_body.getVoluntaryExits().items.len == 0);

    // altair
    const sync_aggregate = block_body.getSyncAggregate();
    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 96, &sync_aggregate.sync_committee_signature);

    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 32, &block_body.getExecutionPayload().electra.parent_hash);
    // another way to access the parent_hash
    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 32, &block_body.getExecutionPayload().getParentHash());

    // capella
    try expect(block_body.getBlsToExecutionChanges().items.len == 0);

    // deneb
    try expect(block_body.getBlobKzgCommitments().items.len == 0);

    // electra
    const execution_request = block_body.getExecutionRequests();
    try expect(execution_request.deposits.items.len == 0);
    try expect(execution_request.withdrawals.items.len == 0);
    try expect(execution_request.consolidations.items.len == 0);
}
