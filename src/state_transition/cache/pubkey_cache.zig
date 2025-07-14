const std = @import("std");
const Allocator = std.mem.Allocator;
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

/// consumers should deinit each item inside Index2PubkeyCache
pub fn syncPubkeys(
    allocator: Allocator,
    validators: ValidatorList,
    pubkey_to_index: *PubkeyIndexMap,
    index_to_pubkey: *Index2PubkeyCache,
) !void {
    if (pubkey_to_index.size() != index_to_pubkey.items.len) {
        return error.InvalidCacheSize;
    }

    try index_to_pubkey.ensureTotalCapacity(validators.items.len);
    index_to_pubkey.expandToCapacity();

    const new_count = validators.items.len;
    for (index_to_pubkey.items.len..new_count) |i| {
        const pubkey = validators.items[i].pubkey;
        // TODO: make pubkey_to_index generic: accept both usize and u32
        try pubkey_to_index.set(&pubkey, @intCast(i));
        const pk = try PublicKey.fromBytes(&pubkey);
        const pk_ptr = try allocator.create(PublicKey);
        pk_ptr.* = pk;
        index_to_pubkey.items[i] = pk_ptr;
    }
}

// TODO: unit tests
