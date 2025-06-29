const types = @import("../type.zig");
const Domain = types.Domain;
const Root = types.Root;
const SigningData = types.SigningData;
const ssz = @import("consensus_types");

/// Return the signing root of an object by calculating the root of the object-domain tree.
pub fn computeSigningRoot(comptime T: type, ssz_object: *const T.Type, domain: Domain, out: *[32]u8) !void {
    var object_root: Root = undefined;
    try T.hashTreeRoot(ssz_object, &object_root);
    const domain_wrapped_object: SigningData = .{
        .object_root = object_root,
        .domain = domain,
    };

    try ssz.phase0.SigningData.hashTreeRoot(&domain_wrapped_object, out);
}

test "computeSigningRoot - sanity" {
    const ssz_type = ssz.phase0.Checkpoint;
    const ssz_object: ssz.phase0.Checkpoint.Type = .{
        .epoch = 1,
        .root = [_]u8{0x01} ** 32,
    };

    const domain = [_]u8{0x01} ** 32;
    var out: [32]u8 = undefined;
    try computeSigningRoot(ssz_type, &ssz_object, domain, &out);
}
