const std = @import("std");
const ArrayList = std.ArrayList;
const ssz = @import("consensus_types");
const chain_config = @import("config").mainnet_chain_config;
const preset = ssz.preset;

const G2_POINT_AT_INFINITY = @import("../constants.zig").G2_POINT_AT_INFINITY;
const ZERO_HASH = @import("../constants.zig").ZERO_HASH;

const ValidatorIndex = @import("../type.zig").ValidatorIndex;
const SingleSignatureSet = @import("../utils/signature_sets.zig").SingleSignatureSet;
const AggregatedSignatureSet = @import("../utils/signature_sets.zig").AggregatedSignatureSet;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const SignedBlock = @import("../signed_block.zig").SignedBlock;
const SignedBeaconBlock = @import("../state_transition.zig").SignedBeaconBlock;
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
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
        const sync_committee_signature_set = try getSyncCommitteeSignatureSet(allocator, state, &signed_block, null);

        if (sync_committee_signature_set) |s| try aggregated_signature_sets.append(s);
    }

    if (fork.isPostCapella()) {
        try getBlsToExecutionChangeSignatureSets(state.config, signed_block.regular, &single_signature_sets);
    }

    return .{ single_signature_sets, aggregated_signature_sets };
}

fn randomBytes(prng: *std.Random.DefaultPrng) [32]u8 {
    var buf: [32]u8 = undefined;
    prng.random().bytes(&buf);
    return buf;
}

test "blockSignatureSets" {
    const allocator = std.testing.allocator;

    var electra_block: ssz.electra.BeaconBlock.Type = ssz.electra.BeaconBlock.default_value;

    var prng = std.Random.DefaultPrng.init(0);
    // electra_block.slot = chain_config.ELECTRA_FORK_EPOCH * preset.SLOTS_PER_EPOCH + 2025 * preset.SLOTS_PER_EPOCH - 1;
    electra_block.parent_root = randomBytes(&prng);
    electra_block.body.eth1_data.deposit_root = randomBytes(&prng);
    electra_block.body.eth1_data.block_hash = randomBytes(&prng);
    electra_block.body.graffiti = randomBytes(&prng);
    var proposer_slashings = [_]ssz.electra.ProposerSlashing.Type{
        ssz.electra.ProposerSlashing.default_value,
    };

    electra_block.body.proposer_slashings = std.ArrayListUnmanaged(ssz.electra.ProposerSlashing.Type).fromOwnedSlice(&proposer_slashings);
    var attester_slashings = [_]ssz.electra.AttesterSlashing.Type{
        ssz.electra.AttesterSlashing.default_value,
    };
    electra_block.body.attester_slashings = std.ArrayListUnmanaged(ssz.electra.AttesterSlashing.Type).fromOwnedSlice(&attester_slashings);
    var voluntary_exits = [_]ssz.electra.SignedVoluntaryExit.Type{
        ssz.electra.SignedVoluntaryExit.default_value,
    };
    electra_block.body.voluntary_exits = std.ArrayListUnmanaged(ssz.electra.SignedVoluntaryExit.Type).fromOwnedSlice(&voluntary_exits);
    var sync_aggregate = ssz.electra.SyncAggregate.default_value;
    sync_aggregate.sync_committee_signature = G2_POINT_AT_INFINITY;
    electra_block.body.sync_aggregate = sync_aggregate;

    const attestation = ssz.electra.Attestation.default_value;
    var attestations = [_]ssz.electra.Attestation.Type{attestation};
    electra_block.body.attestations = std.ArrayListUnmanaged(ssz.electra.Attestation.Type).fromOwnedSlice(&attestations);

    const validator_count = 32;
    var test_state = try TestCachedBeaconStateAllForks.init(allocator, validator_count);
    defer test_state.deinit();

    const beacon_block = ssz.electra.SignedBeaconBlock.Type{
        .message = electra_block,
        .signature = ssz.primitive.BLSSignature.default_value,
    };
    const signed_beacon_block = SignedBeaconBlock{ .electra = &beacon_block };
    const signed_block = SignedBlock{ .regular = &signed_beacon_block };

    const signature_sets = try blockSignatureSets(allocator, test_state.cached_state, signed_block, .{ .skip_proposer_signature = false });
    defer signature_sets[0].deinit();
    defer signature_sets[1].deinit();

    const expected = 1 // block signature
        + 1 // randao reveal
        + 2 //proposer slashings
        + 2 // attester slashings
        + 1 //attestation
        + 1; //voluntary exit

    try std.testing.expect(signature_sets[0].items.len + signature_sets[1].items.len == expected);
}
