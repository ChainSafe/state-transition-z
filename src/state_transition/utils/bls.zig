const std = @import("std");
const Allocator = std.mem.Allocator;
const blst = @import("blst_min_pk");
const aggregateSerializedPublicKeys = blst.AggregatePublicKey.aggregateSerialized;
const MemoryPool = blst.MemoryPool;
const initializeThreadPool = blst.initializeThreadPool;
const deinitializeThreadPool = blst.deinitializeThreadPool;
const PublicKey = blst.PublicKey;
const Signature = blst.Signature;
const SecretKey = blst.SecretKey;

/// See https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#bls-signatures
const DST: []const u8 = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_";

// TODO: should it be threadlocal? MemoryPool is thread safe in its implementation
var memory_pool: ?*MemoryPool = null;

pub fn initBlst(allocator: Allocator) !void {
    try initializeThreadPool(allocator);
    _ = try getMemoryPool(allocator);
}

pub fn deinitBlst(allocator: Allocator) void {
    if (memory_pool) |pool| {
        pool.deinit();
        allocator.destroy(pool);
        memory_pool = null;
    }
    deinitializeThreadPool();
}

/// this is supposed to be called from the main thread so we dont need mutex here
fn getMemoryPool(allocator: Allocator) !*MemoryPool {
    if (memory_pool) |pool| {
        return pool;
    }
    var mem_pool = try allocator.create(MemoryPool);
    try mem_pool.init(allocator);
    memory_pool = mem_pool;
    return mem_pool;
}

pub fn sign(secret_key: SecretKey, msg: []const u8) Signature {
    return secret_key.sign(msg, DST, null);
}

/// Verify a signature against a message and public key.
///
/// If `pk_validate` is `true`, the public key will be infinity and group checked.
///
/// If `sig_groupcheck` is `true`, the signature will be group checked.
pub fn verify(msg: []const u8, pk: *const PublicKey, sig: *const Signature, in_pk_validate: ?bool, in_sig_groupcheck: ?bool) bool {
    const sig_groupcheck = in_sig_groupcheck orelse false;
    const pk_validate = in_pk_validate orelse false;
    sig.verify(sig_groupcheck, msg, DST, null, pk, pk_validate) catch return false;
    return true;
}

pub fn fastAggregateVerify(allocator: Allocator, msg: []const u8, pks: []*const PublicKey, sig: *const Signature, in_sigs_group_check: ?bool) !bool {
    const sigs_groupcheck = in_sigs_group_check orelse false;
    const pool = try getMemoryPool(allocator);
    sig.fastAggregateVerify(sigs_groupcheck, msg, DST, pks, pool) catch return false;
    return true;
}

// TODO: unit tests
test "bls - sanity" {
    const ikm: [32]u8 = [_]u8{
        0x93, 0xad, 0x7e, 0x65, 0xde, 0xad, 0x05, 0x2a, 0x08, 0x3a,
        0x91, 0x0c, 0x8b, 0x72, 0x85, 0x91, 0x46, 0x4c, 0xca, 0x56,
        0x60, 0x5b, 0xb0, 0x56, 0xed, 0xfe, 0x2b, 0x60, 0xa6, 0x3c,
        0x48, 0x99,
    };
    const sk = try SecretKey.keyGen(ikm[0..], null);
    const msg = [_]u8{1} ** 32;
    const sig = sign(sk, &msg);
    const pk = sk.skToPk();
    try std.testing.expect(verify(&msg, &pk, &sig, null, null));

    const allocator = std.testing.allocator;
    try initBlst(allocator);
    defer deinitBlst(allocator);

    // TODO: why cannot compile this with zig 0.14
    // const pks = [_]*const PublicKey{&pk};
    // const pks_slice: []*const PublicKey = pks[0..];
    var pks: [1]*const PublicKey = undefined;
    pks[0] = &pk;
    const pks_slice = pks[0..1];
    const result = try fastAggregateVerify(allocator, &msg, pks_slice, &sig, null);
    try std.testing.expect(result);
}
