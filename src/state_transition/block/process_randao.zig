const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const params = @import("params");
const ForkSeq = @import("params").ForkSeq;
const BeaconBlock = @import("../types/beacon_block.zig").BeaconBlock;
const BeaconBlockBody = @import("../types/beacon_block.zig").BeaconBlockBody;
const Bytes32 = ssz.primitive.Bytes32.Type;
const verifyRandaoSignature = @import("../signature_sets/randao.zig").verifyRandaoSignature;
const digest = @import("../utils/sha256.zig").digest;

pub fn processRandao(cached_state: *const CachedBeaconStateAllForks, block: *const BeaconBlock, verify_signature: ?bool) !void {
    const state = cached_state.state;
    const epoch_cache = cached_state.epoch_cache;
    const epoch = epoch_cache.epoch;
    const randao_reveal = block.getBeaconBlockBody().getRandaoReveal();

    // verify RANDAO reveal
    if (verify_signature orelse false) {
        if (!verifyRandaoSignature(state, block)) {
            return error.InvalidRandaoSignature;
        }
    }

    // mix in RANDAO reveal
    var randao_reveal_digest: [32]u8 = undefined;
    digest(randao_reveal, &randao_reveal_digest);
    const randao_mix = xor(state.getRandaoMix(epoch), randao_reveal_digest);
    state.setRandaoMix(epoch % preset.EPOCHS_PER_HISTORICAL_VECTOR, randao_mix);
}

fn xor(a: Bytes32, b: Bytes32) Bytes32 {
    var result: Bytes32 = undefined;
    for (0..Bytes32.len) |i| {
        result[i] = a[i] ^ b[i];
    }
    return result;
}
