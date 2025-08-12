const std = @import("std");
const ArrayList = std.ArrayList;
const ssz = @import("consensus_types");

const ValidatorIndex = @import("../type.zig").ValidatorIndex;
const SingleSignatureSet = @import("../utils/signature_sets.zig").SingleSignatureSet;
const AggregatedSignatureSet = @import("../utils/signature_sets.zig").AggregatedSignatureSet;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const SignedBlock = @import("../signed_block.zig").SignedBlock;
const SignedBeaconBlock = @import("../state_transition.zig").SignedBeaconBlock;
const TestCachedBeaconStateAllForks = @import("../test_utils/cached_beacon_state.zig").TestCachedBeaconStateAllForks;
const getRandaoRevealSignatureSet = @import("./randao.zig").getRandaoRevealSignatureSet;
const getProposerSlashingsSignatureSets = @import("./proposer_slashings.zig").getProposerSlashingsSignatureSets;
const getAttesterSlashingsSignatureSets = @import("./attester_slashings.zig").getAttesterSlashingsSignatureSets;
const getAttestationsSignatureSets = @import("./indexed_attestation.zig").getAttestationsSignatureSets;
const getVoluntaryExitsSignatureSets = @import("./voluntary_exits.zig").getVoluntaryExitsSignatureSets;
const getSyncCommitteeSignatureSet = @import("../../state_transition/block/process_sync_committee.zig").getSyncCommitteeSignatureSet;
const getBlsToExecutionChangeSignatureSets = @import("./bls_to_execution_change.zig").getBlsToExecutionChangeSignatureSets;
const getBlockProposerSignatureSet = @import("./proposer.zig").getBlockProposerSignatureSet;

const SignatureSetOpt = struct {
    /// Useful since block proposer signature is verified beforehand on gossip validation.
    skip_proposer_signature: bool = true,
};
pub fn blockSignatureSets(
    allocator: std.mem.Allocator,
    state: *const CachedBeaconStateAllForks,
    signed_block: SignedBlock,
    opt: SignatureSetOpt,
) !struct { ArrayList(SingleSignatureSet), ArrayList(AggregatedSignatureSet) } {
    const fork = state.state.getForkSeq();
    var single_signature_sets = ArrayList(SingleSignatureSet).init(allocator);
    errdefer single_signature_sets.deinit();
    var aggregated_signature_sets = ArrayList(AggregatedSignatureSet).init(allocator);
    errdefer aggregated_signature_sets.deinit();

    try single_signature_sets.append(try getRandaoRevealSignatureSet(state, &signed_block.getBeaconBlockBody(), signed_block.getSlot(), signed_block.getProposerIndex()));
    try getProposerSlashingsSignatureSets(state, signed_block.regular, &single_signature_sets);
    try getAttesterSlashingsSignatureSets(allocator, state, signed_block.regular, &aggregated_signature_sets);
    try getAttestationsSignatureSets(allocator, state, signed_block.regular, &aggregated_signature_sets);
    try getVoluntaryExitsSignatureSets(state, signed_block.regular, &single_signature_sets);

    if (!opt.skip_proposer_signature) {
        try single_signature_sets.append(try getBlockProposerSignatureSet(allocator, state, &signed_block));
    }

    if (fork.isPostAltair()) {
        const epoch_cache = state.getEpochCache();
        const committee_indices = epoch_cache.current_sync_committee_indexed.get().getValidatorIndices();
        const participant_indices = try signed_block.getBeaconBlockBody().syncAggregate().sync_committee_bits.intersectValues(
            ValidatorIndex,
            allocator,
            committee_indices,
        );
        defer participant_indices.deinit();
        const sync_committee_signature_set = try getSyncCommitteeSignatureSet(allocator, state, &signed_block, participant_indices.items);

        if (sync_committee_signature_set) |s| try aggregated_signature_sets.append(s);
    }

    if (fork.isPostCapella()) {
        try getBlsToExecutionChangeSignatureSets(state.config, signed_block.regular, &single_signature_sets);
    }

    return .{ single_signature_sets, aggregated_signature_sets };
}

test "blockSignatureSets" {
    const allocator = std.testing.allocator;
    const validator_count = 256;
    var test_state = try TestCachedBeaconStateAllForks.init(allocator, validator_count);
    defer test_state.deinit();

    const block = &ssz.electra.SignedBeaconBlock.default_value;
    const signed_beacon_block = SignedBeaconBlock{ .electra = block };
    const signed_block = SignedBlock{ .regular = &signed_beacon_block };

    const signature_sets = try blockSignatureSets(allocator, test_state.cached_state, signed_block, .{});
    defer signature_sets.@"0".deinit();
    defer signature_sets.@"1".deinit();
    std.debug.print("{}", .{signature_sets[0]});
}
