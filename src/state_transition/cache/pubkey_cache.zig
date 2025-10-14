const std = @import("std");
const Allocator = std.mem.Allocator;
const blst = @import("blst");
const ssz = @import("consensus_types");
const PublicKey = blst.PublicKey;
const ValidatorIndex = ssz.primitive.ValidatorIndex.Type;
const PubkeyIndexMap = @import("../stdx/pubkey_index_map.zig").PubkeyIndexMap(ValidatorIndex);
const Validator = ssz.phase0.Validator.Type;
// ArrayListUnmanaged is used in ssz VariableListType
const ValidatorList = std.ArrayListUnmanaged(Validator);

pub const Index2PubkeyCache = std.ArrayList(PublicKey);

/// consumers should deinit each item inside Index2PubkeyCache
pub fn syncPubkeys(
    validators: []Validator,
    pubkey_to_index: *PubkeyIndexMap,
    index_to_pubkey: *Index2PubkeyCache,
) !void {
    if (pubkey_to_index.size() != index_to_pubkey.items.len) {
        // TODO: is this a good pattern to debug?
        std.debug.print("Error: Pubkey-to-index map size ({d}) does not match index-to-pubkey list length ({d})\n", .{ pubkey_to_index.size(), index_to_pubkey.items.len });
        return error.InvalidPubkeyIndexMap;
    }

    const old_len = index_to_pubkey.items.len;
    try index_to_pubkey.resize(validators.len);

    const new_count = validators.len;
    for (old_len..new_count) |i| {
        const pubkey = validators[i].pubkey;
        try pubkey_to_index.set(&pubkey, @intCast(i));
        index_to_pubkey.items[i] = try PublicKey.uncompress(&pubkey);
    }
}

// TODO: unit tests
