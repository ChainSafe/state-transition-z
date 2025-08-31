const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const params = @import("params");
const ForkSeq = @import("params").ForkSeq;
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const BeaconBlockBody_ = @import("../signed_block.zig").SignedBlock.BeaconBlockBody_;
const Bytes32 = ssz.primitive.Bytes32.Type;
const getRandaoMix = @import("../utils/seed.zig").getRandaoMix;
const verifyRandaoSignature = @import("../signature_sets/randao.zig").verifyRandaoSignature;
const digest = @import("../utils/sha256.zig").digest;

pub fn processRandao(
    cached_state: *const CachedBeaconStateAllForks,
    body: *const BeaconBlockBody_,
    proposer_idx: u64,
    verify_signature: bool,
) !void {
    const state = cached_state.state;
    const epoch_cache = cached_state.getEpochCache();
    const epoch = epoch_cache.epoch;
    const randao_reveal = body.getRandaoReveal();

    // verify RANDAO reveal
    if (verify_signature) {
        if (!try verifyRandaoSignature(cached_state, body, cached_state.state.slot(), proposer_idx)) {
            return error.InvalidRandaoSignature;
        }
    }

    // mix in RANDAO reveal
    var randao_reveal_digest: [32]u8 = undefined;
    digest(&randao_reveal, &randao_reveal_digest);
    const randao_mix = xor(getRandaoMix(state, epoch), randao_reveal_digest);
    const state_randao_mixes = state.randaoMixes();
    state_randao_mixes[epoch % preset.EPOCHS_PER_HISTORICAL_VECTOR] = randao_mix;
}

fn xor(a: Bytes32, b: Bytes32) Bytes32 {
    var result: Bytes32 = undefined;
    for (0..ssz.primitive.Bytes32.length) |i| {
        result[i] = a[i] ^ b[i];
    }
    return result;
}
