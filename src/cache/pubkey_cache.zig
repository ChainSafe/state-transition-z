const std = @import("std");
const blst = @import("blst_min_pk");
const ssz = @import("consensus_types");
const PublicKey = blst.PublicKey;
const PubkeyIndexMap = @import("../utils/pubkey_index_map.zig").PubkeyIndexMap;
const Validator = ssz.phase0.Validator.Type;
// ArrayListUnmanaged is used in ssz VariableListType
const ValidatorList = std.ArrayListUnmanaged(Validator);

// TODO: blst requires *const PublicKey while ssz uses PublicKey inside Validator
// so need to convert PublicKey to *const PublicKey
pub const Index2PubkeyCache = std.ArrayList(*const PublicKey);

pub fn syncPubkeys(
    validators: ValidatorList,
    pubkey_to_index: PubkeyIndexMap,
    index_to_pubkey: Index2PubkeyCache,
) !void {
    if (pubkey_to_index.size() != index_to_pubkey.items.len) {
        return error.InvalidCacheSize;
    }

    const new_count = validators.items.len;
    for (index_to_pubkey.items.len..new_count) |i| {
        const pubkey = validators.items[i].pubkey;
        try pubkey_to_index.set(pubkey[0..], i);
        index_to_pubkey[i] = try PublicKey.fromBytes(pubkey);
    }
}

// TODO: unit tests
