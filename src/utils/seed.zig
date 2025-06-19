const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const BeaconStateAllForks = @import("../beacon_state.zig").BeaconStateAllForks;
const digest = @import("./sha256.zig").digest;
const Epoch = ssz.primitive.Epoch.Type;
const Bytes32 = ssz.primitive.Bytes32.Type;
const DomainType = ssz.primitive.DomainType.Type;
const EPOCHS_PER_HISTORICAL_VECTOR = ssz.preset.EPOCHS_PER_HISTORICAL_VECTOR;
const MIN_SEED_LOOKAHEAD = ssz.preset.MIN_SEED_LOOKAHEAD;

pub fn getRandaoMix(state: BeaconStateAllForks, epoch: Epoch) Bytes32 {
    return state.getRanDaoMix(epoch % EPOCHS_PER_HISTORICAL_VECTOR);
}

pub fn getSeed(state: BeaconStateAllForks, epoch: Epoch, domain_type: DomainType, out: *[32]u8) !void {
    const mix = getRandaoMix(state, epoch + EPOCHS_PER_HISTORICAL_VECTOR - MIN_SEED_LOOKAHEAD - 1);
    var epoch_buf: [8]u8 = undefined;
    std.mem.writeInt(u64, &epoch_buf, epoch, .little);
    var buffer = [_]u8{0} ** (DomainType.len + 8 + Bytes32.len);
    std.mem.copyForwards(u8, out[0..domain_type.len], domain_type[0..]);
    std.mem.copyForwards(u8, out[domain_type.len .. domain_type.len + 8], epoch_buf[0..]);
    std.mem.copyForwards(u8, out[domain_type.len + 8 ..], mix[0..]);
    digest(buffer[0..], out);
}
