const std = @import("std");
const snappy = @import("snappy");
const ForkSeq = @import("config").ForkSeq;
const isFixedType = @import("ssz").isFixedType;
const BeaconStateAllForks = @import("state_transition").BeaconStateAllForks;

const consensus_types = @import("consensus_types");
const phase0 = consensus_types.phase0;
const altair = consensus_types.altair;
const bellatrix = consensus_types.bellatrix;
const capella = consensus_types.capella;
const deneb = consensus_types.deneb;
const electra = consensus_types.electra;
const fulu = consensus_types.fulu;

pub const BlsSetting = enum {
    default,
    required,
    ignored,

    pub fn verify(self: BlsSetting) bool {
        return switch (self) {
            .default, .required => true,
            .ignored => false,
        };
    }
};

pub fn loadBlsSetting(allocator: std.mem.Allocator, dir: std.fs.Dir) BlsSetting {
    var file = dir.openFile("meta.yaml", .{}) catch return .default;
    defer file.close();

    const contents = file.readToEndAlloc(allocator, 100) catch return .default;
    defer allocator.free(contents);

    if (std.mem.indexOf(u8, contents, "bls_setting: 0") != null) {
        return .default;
    } else if (std.mem.indexOf(u8, contents, "bls_setting: 1") != null) {
        return .required;
    } else if (std.mem.indexOf(u8, contents, "bls_setting: 2") != null) {
        return .ignored;
    } else {
        return .default;
    }
}

pub fn loadSszSnappyValue(comptime ST: type, allocator: std.mem.Allocator, dir: std.fs.Dir, file_name: []const u8, out: *ST.Type) !void {
    var object_file = try dir.openFile(file_name, .{});
    defer object_file.close();

    const value_bytes = try object_file.readToEndAlloc(allocator, 100_000_000);
    defer allocator.free(value_bytes);

    const serialized_buf = try allocator.alloc(u8, try snappy.uncompressedLength(value_bytes));
    defer allocator.free(serialized_buf);
    const serialized_len = try snappy.uncompress(value_bytes, serialized_buf);
    const serialized = serialized_buf[0..serialized_len];

    if (comptime isFixedType(ST)) {
        try ST.deserializeFromBytes(serialized, out);
    } else {
        try ST.deserializeFromBytes(allocator, serialized, out);
    }
}

pub fn expectEqualBeaconStates(expected: BeaconStateAllForks, actual: BeaconStateAllForks) !void {
    if (expected.forkSeq() != actual.forkSeq()) return error.ForkMismatch;

    switch (expected.forkSeq()) {
        .phase0 => {
            if (!phase0.BeaconState.equals(expected.phase0, actual.phase0)) return error.NotEqual;
        },
        .altair => {
            if (!altair.BeaconState.equals(expected.altair, actual.altair)) return error.NotEqual;
        },
        .bellatrix => {
            if (!bellatrix.BeaconState.equals(expected.bellatrix, actual.bellatrix)) return error.NotEqual;
        },
        .capella => {
            if (!capella.BeaconState.equals(expected.capella, actual.capella)) return error.NotEqual;
        },
        .deneb => {
            if (!deneb.BeaconState.equals(expected.deneb, actual.deneb)) return error.NotEqual;
        },
        .electra => {
            if (!electra.BeaconState.equals(expected.electra, actual.electra)) return error.NotEqual;
        },
        .fulu => {
            if (!fulu.BeaconState.equals(expected.fulu, actual.fulu)) return error.NotEqual;
        },
    }
}
