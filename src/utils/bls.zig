pub const blst = @import("blst_min_pk");
pub const aggregateSerializedPublicKeys = blst.AggregatePublicKey.aggregateSerialized;
const PublicKey = blst.PublicKey;
const Signature = blst.Signature;
/// See https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#bls-signatures
const DST: []const u8 = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_";

/// Verify a signature against a message and public key.
///
/// If `pk_validate` is `true`, the public key will be infinity and group checked.
///
/// If `sig_groupcheck` is `true`, the signature will be group checked.
pub fn verify(msg: []const u8, pk: *const PublicKey, sig: *const Signature, in_pk_validate: ?bool, in_sig_groupcheck: ?bool) bool {
    const sig_groupcheck = in_sig_groupcheck orelse false;
    const pk_validate = in_pk_validate orelse false;
    return sig.verify(sig_groupcheck, msg, DST, null, pk, pk_validate);
}
