const std = @import("std");
const Allocator = std.mem.Allocator;
const blst_min_pk = @import("blst_min_pk");
const ssz = @import("consensus_types");
const BLSPubkey = ssz.primitive.BLSPubkey;
const Secretkey = blst_min_pk.SecretKey;

/// Generates a list of BLS public keys for interop testing.
// TODO: store this to a file and cache there
pub fn interopPubkeysCached(allocator: Allocator, validator_count: usize) !std.ArrayList(BLSPubkey) {
    var pubkeys = std.ArrayList(BLSPubkey).initCapacity(allocator, validator_count);

    for (0..validator_count) |i| {
        const ikm = [_]u8{i % 256} ** 32;
        const sk = try Secretkey.keyGen(&ikm, null);
        const pk = sk.skToPk();
        try pubkeys.append(pk.toBytes());
    }

    return pubkeys;
}
