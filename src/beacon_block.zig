const std = @import("std");
const expect = std.testing.expect;
const ssz = @import("consensus_types");
const types = @import("./type.zig");
const Slot = types.Slot;
const ValidatorIndex = types.ValidatorIndex;
const Root = types.Root;

pub const SignedBeaconBlock = union(enum) {
    phase0: ssz.phase0.SignedBeaconBlock.Type,
    altair: ssz.altair.SignedBeaconBlock.Type,
    bellatrix: ssz.bellatrix.SignedBeaconBlock.Type,
    capella: ssz.capella.SignedBeaconBlock.Type,
    deneb: ssz.deneb.SignedBeaconBlock.Type,
    electra: ssz.electra.SignedBeaconBlock.Type,

    pub fn getBeaconBlock(self: *const SignedBeaconBlock) BeaconBlock {
        return switch (self.*) {
            .phase0 => |block| .{ .phase0 = block.message },
            .altair => |block| .{ .altair = block.message },
            .bellatrix => |block| .{ .bellatrix = block.message },
            .capella => |block| .{ .capella = block.message },
            .deneb => |block| .{ .deneb = block.message },
            .electra => |block| .{ .electra = block.message },
        };
    }
};

// TODO: also model BlindedBeaconBlock in this enum?

pub const BeaconBlock = union(enum) {
    phase0: ssz.phase0.BeaconBlock.Type,
    altair: ssz.altair.BeaconBlock.Type,
    bellatrix: ssz.bellatrix.BeaconBlock.Type,
    capella: ssz.capella.BeaconBlock.Type,
    deneb: ssz.deneb.BeaconBlock.Type,
    electra: ssz.electra.BeaconBlock.Type,

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
            .phase0 => |block| .{ .phase0 = block.body },
            .altair => |block| .{ .altair = block.body },
            .bellatrix => |block| .{ .bellatrix = block.body },
            .capella => |block| .{ .capella = block.body },
            .deneb => |block| .{ .deneb = block.body },
            .electra => |block| .{ .electra = block.body },
        };
    }
};

pub const BeaconBlockBody = union(enum) {
    phase0: ssz.phase0.BeaconBlockBody.Type,
    altair: ssz.altair.BeaconBlockBody.Type,
    bellatrix: ssz.bellatrix.BeaconBlockBody.Type,
    capella: ssz.capella.BeaconBlockBody.Type,
    deneb: ssz.deneb.BeaconBlockBody.Type,
    electra: ssz.electra.BeaconBlockBody.Type,

    // phase0 fields
    pub fn getRandaoReveal(self: *const BeaconBlockBody) ssz.primitive.BLSSignature.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| body.randao_reveal,
        };
    }

    pub fn getEth1Data(self: *const BeaconBlockBody) ssz.phase0.Eth1Data.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| body.eth1_data,
        };
    }

    pub fn getGraffity(self: *const BeaconBlockBody) ssz.primitive.Bytes32.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| body.graffiti,
        };
    }

    pub fn getProposerSlashings(self: *const BeaconBlockBody) ssz.phase0.ProposerSlashings.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| body.proposer_slashings,
        };
    }

    pub fn getAttesterSlashings(self: *const BeaconBlockBody) ssz.phase0.AttesterSlashings.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| body.attester_slashings,
        };
    }

    pub fn getAttestations(self: *const BeaconBlockBody) Attestations {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb => |body| .{ .phase0 = body.attestations },
            .electra => |body| .{ .electra = body.attestations },
        };
    }

    pub fn getDeposits(self: *const BeaconBlockBody) ssz.phase0.Deposits.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| body.deposits,
        };
    }

    pub fn getVoluntaryExits(self: *const BeaconBlockBody) ssz.phase0.VoluntaryExits.Type {
        return switch (self.*) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb, .electra => |body| body.voluntary_exits,
        };
    }

    // altair fields
    pub fn getSyncAggregate(self: *const BeaconBlockBody) ssz.altair.SyncAggregate.Type {
        return switch (self.*) {
            inline .altair, .bellatrix, .capella, .deneb, .electra => |body| body.sync_aggregate,
            else => @panic("SyncAggregate is not available in phase0"),
        };
    }

    // bellatrix fields
    pub fn getExecutionPayload(self: *const BeaconBlockBody) ExecutionPayload {
        return switch (self.*) {
            inline .phase0, .altair => @panic("ExecutionPayload is not available in phase0 or altair"),
            .bellatrix => |body| .{ .bellatrix = body.execution_payload },
            .capella => |body| .{ .capella = body.execution_payload },
            .deneb => |body| .{ .deneb = body.execution_payload },
            .electra => |body| .{ .electra = body.execution_payload },
        };
    }

    // capella fields
    pub fn getBlsToExecutionChanges(self: *const BeaconBlockBody) ssz.capella.SignedBLSToExecutionChanges.Type {
        return switch (self.*) {
            .phase0,
            => @panic("BlsToExecutionChanges is not available in phase0"),
            .altair => @panic("BlsToExecutionChanges is not available in altair"),
            .bellatrix => @panic("BlsToExecutionChanges is not available in bellatrix"),
            .capella => |body| body.bls_to_execution_changes,
            .deneb => |body| body.bls_to_execution_changes,
            .electra => |body| body.bls_to_execution_changes,
        };
    }

    // deneb fields
    pub fn getBlobKzgCommitments(self: *const BeaconBlockBody) ssz.deneb.BlobKzgCommitments.Type {
        return switch (self.*) {
            .phase0 => @panic("BlobKzgCommitments is not available in phase0"),
            .altair => @panic("BlobKzgCommitments is not available in altair"),
            .bellatrix => @panic("BlobKzgCommitments is not available in bellatrix"),
            .capella => @panic("BlobKzgCommitments is not available in capella"),
            .deneb => |body| body.blob_kzg_commitments,
            .electra => |body| body.blob_kzg_commitments,
        };
    }

    // electra fields
    pub fn getExecutionRequests(self: *const BeaconBlockBody) ssz.electra.ExecutionRequests.Type {
        return switch (self.*) {
            .phase0 => @panic("ExecutionRequests is not available in phase0"),
            .altair => @panic("ExecutionRequests is not available in altair"),
            .bellatrix => @panic("ExecutionRequests is not available in bellatrix"),
            .capella => @panic("ExecutionRequests is not available in capella"),
            .deneb => @panic("ExecutionRequests is not available in deneb"),
            .electra => |body| body.execution_requests,
        };
    }
};

pub const ExecutionPayload = union(enum) {
    bellatrix: ssz.bellatrix.ExecutionPayload.Type,
    capella: ssz.capella.ExecutionPayload.Type,
    deneb: ssz.deneb.ExecutionPayload.Type,
    electra: ssz.electra.ExecutionPayload.Type,

    pub fn getParentHash(self: *const ExecutionPayload) ssz.primitive.Bytes32.Type {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.parent_hash,
        };
    }

    pub fn getFeeRecipient(self: *const ExecutionPayload) ssz.primitive.Bytes20.Type {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.fee_recipient,
        };
    }

    pub fn getStateRoot(self: *const ExecutionPayload) ssz.primitive.Bytes32.Type {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.state_root,
        };
    }

    pub fn getReceiptsRoot(self: *const ExecutionPayload) ssz.primitive.Bytes32.Type {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.receipts_root,
        };
    }

    pub fn getLogsBloom(self: *const ExecutionPayload) ssz.bellatrix.LogsBoom.Type {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.logs_bloom,
        };
    }

    pub fn getPrevRandao(self: *const ExecutionPayload) ssz.primitive.Bytes32.Type {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.prev_randao,
        };
    }

    pub fn getBlockNumber(self: *const ExecutionPayload) u64 {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.block_number,
        };
    }

    pub fn getGasLimit(self: *const ExecutionPayload) u64 {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.gas_limit,
        };
    }

    pub fn getGasUsed(self: *const ExecutionPayload) u64 {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.gas_used,
        };
    }

    pub fn getTimestamp(self: *const ExecutionPayload) u64 {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.timestamp,
        };
    }

    pub fn getExtraData(self: *const ExecutionPayload) ssz.bellatrix.ExtraData.Type {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.extra_data,
        };
    }

    pub fn getBaseFeePerGas(self: *const ExecutionPayload) u256 {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.base_fee_per_gas,
        };
    }

    pub fn getBlockHash(self: *const ExecutionPayload) ssz.primitive.Bytes32.Type {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.block_hash,
        };
    }

    pub fn getTransactions(self: *const ExecutionPayload) ssz.bellatrix.Transactions.Type {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.transactions,
        };
    }

    pub fn getWithdrawals(self: *const ExecutionPayload) ssz.capella.Withdrawals.Type {
        return switch (self.*) {
            .bellatrix => @panic("Withdrawals are not available in bellatrix"),
            inline .capella, .deneb, .electra => |payload| payload.withdrawals,
        };
    }

    pub fn getBlobGasUsed(self: *const ExecutionPayload) u64 {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.blob_gas_used,
        };
    }

    pub fn getExcessBlobGas(self: *const ExecutionPayload) u64 {
        return switch (self.*) {
            inline .bellatrix, .capella, .deneb, .electra => |payload| payload.excess_blob_gas,
        };
    }
};

pub const Attestations = union(enum) {
    phase0: ssz.phase0.Attestations.Type,
    electra: ssz.electra.Attestations.Type,

    pub fn length(self: *const Attestations) usize {
        return switch (self.*) {
            inline .phase0, .electra => |attestations| attestations.items.len,
        };
    }

    pub fn items(self: *const Attestations) AttestationItems {
        return switch (self.*) {
            .phase0 => |attestations| .{ .phase0 = attestations.items },
            .electra => |attestations| .{ .electra = attestations.items },
        };
    }
};

pub const AttestationItems = union(enum) {
    phase0: []ssz.phase0.Attestation.Type,
    electra: []ssz.electra.Attestation.Type,
};

test "electra - sanity" {
    var electra_block = ssz.electra.BeaconBlock.default_value;
    electra_block.slot = 12345;
    electra_block.proposer_index = 1;
    electra_block.body.randao_reveal = [_]u8{1} ** 96;
    var attestations = try std.ArrayListUnmanaged(ssz.electra.Attestation.Type).initCapacity(std.testing.allocator, 10);
    defer attestations.deinit(std.testing.allocator);
    var attestation0 = ssz.electra.Attestation.default_value;
    attestation0.data.slot = 12345;
    try attestations.append(std.testing.allocator, attestation0);
    electra_block.body.attestations = attestations;
    try expect(electra_block.body.attestations.items[0].data.slot == 12345);
    const beacon_block = BeaconBlock{ .electra = electra_block };

    try expect(beacon_block.getSlot() == 12345);
    try expect(beacon_block.getProposerIndex() == 1);
    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 32, &beacon_block.getParentRoot());
    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 32, &beacon_block.getStateRoot());

    const block_body = beacon_block.getBeaconBlockBody();
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
