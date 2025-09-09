const std = @import("std");
const snappy = @import("snappy");
const ForkSeq = @import("params").ForkSeq;
const BeaconStateAllForks = @import("state_transition").BeaconStateAllForks;

const consensus_types = @import("consensus_types");
const phase0 = consensus_types.phase0;
const altair = consensus_types.altair;
const bellatrix = consensus_types.bellatrix;
const capella = consensus_types.capella;
const deneb = consensus_types.deneb;
const electra = consensus_types.electra;

// TODO: Most of the runners have fixed ssz types ie. Given a dir, we can already derive which
// snappy file has what type and have this info written in test_type/schema.
// There is an exception which is `transition`. One needs to read meta.yaml to figure out
// whether a block_x.ssz_snappy belong to old fork or new fork. Current design of loadTestCase
// does not handle this.
pub fn loadTestCase(comptime Schema: type, dir: std.fs.Dir, allocator: std.mem.Allocator) !Schema {
    var out: Schema = undefined;
    var it = dir.iterate();

    while (try it.next()) |entry| {
        // Ignore all non-file
        if (entry.kind != .file) continue;
        const name = entry.name;
        // Ignore all hidden files
        if (name.len == 0 || (name.len > 0 and name[0] == '.')) continue;

        const dot_idx = std.mem.lastIndexOfScalar(u8, name, '.').?;
        const file_name = name[0..dot_idx];
        const extension = name[dot_idx + 1 ..];

        // Ignore all non-snappy files
        if (!std.mem.eql(u8, extension, "ssz_snappy")) continue;

        var handled = false;
        inline for (@typeInfo(Schema).@"struct".fields) |fld| {
            // TODO: eql works for now. but really should do startsWith
            if (!std.mem.startsWith(u8, file_name, fld.name)) continue;

            const ST = fld.type;
            var object_file = try dir.openFile(name, .{});
            defer object_file.close();

            const value_bytes = try object_file.readToEndAlloc(allocator, 100_000_000);
            defer allocator.free(value_bytes);

            const serialized_buf = try allocator.alloc(u8, try snappy.uncompressedLength(value_bytes));
            defer allocator.free(serialized_buf);
            const serialized_len = try snappy.uncompress(value_bytes, serialized_buf);
            const serialized = serialized_buf[0..serialized_len];

            const value = try allocator.create(ST);
            try ST.deserializeFromBytes(allocator, serialized, value);

            @field(out, fld.name) = value.*;
            handled = true;
            break;
        }

        if (!handled) {
            return error.SchemaLookupError;
        }
    }

    return out;
}

pub fn expectEqualBeaconStates(expected: BeaconStateAllForks, actual: BeaconStateAllForks) !void {
    if (expected.forkSeq() != actual.forkSeq()) return error.ForkMismatch;

    switch (expected.forkSeq()) {
        .phase0 => {
            if (phase0.BeaconState.equals(expected.phase0, actual.phase0)) return error.NotEqual;
        },
        .altair => {
            if (altair.BeaconState.equals(expected.altair, actual.altair)) return error.NotEqual;
        },
        .bellatrix => {
            if (bellatrix.BeaconState.equals(expected.bellatrix, actual.bellatrix)) return error.NotEqual;
        },
        .capella => {
            if (capella.BeaconState.equals(expected.capella, actual.capella)) return error.NotEqual;
        },
        .deneb => {
            if (deneb.BeaconState.equals(expected.deneb, actual.deneb)) return error.NotEqual;
        },
        .electra => {
            if (electra.BeaconState.equals(expected.electra, actual.electra)) return error.NotEqual;
        },
        else => return error.UnsupportedFork,
    }
}
