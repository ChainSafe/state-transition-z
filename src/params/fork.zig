const std = @import("std");
const ssz = @import("consensus_types");
const Epoch = ssz.primitive.Epoch.Type;
const Version = ssz.primitive.Version.Type;

const Fork_Name_Phase0 = "phase0";
const Fork_Name_Altair = "altair";
const Fork_Name_Bellatrix = "bellatrix";
const Fork_Name_Capella = "capella";
const Fork_Name_Deneb = "deneb";
const Fork_Name_Electra = "electra";

pub const TOTAL_FORKS = 6;

pub const ForkSeq = enum(u8) {
    phase0 = 0,
    altair = 1,
    bellatrix = 2,
    capella = 3,
    deneb = 4,
    electra = 5,
    // TODO: fulu

    pub fn getForkName(self: ForkSeq) []const u8 {
        return switch (self) {
            .phase0 => Fork_Name_Phase0,
            .altair => Fork_Name_Altair,
            .bellatrix => Fork_Name_Bellatrix,
            .capella => Fork_Name_Capella,
            .deneb => Fork_Name_Deneb,
            .electra => Fork_Name_Electra,
        };
    }

    pub fn isPostAltair(self: ForkSeq) bool {
        return switch (self) {
            inline .phase0 => false,
            else => true,
        };
    }

    pub fn isPostBellatrix(self: ForkSeq) bool {
        return switch (self) {
            inline .phase0, .altair => false,
            else => true,
        };
    }

    pub fn isPostCapella(self: ForkSeq) bool {
        return switch (self) {
            inline .phase0, .altair, .bellatrix => false,
            else => true,
        };
    }

    pub fn isPostDeneb(self: ForkSeq) bool {
        return switch (self) {
            inline .phase0, .altair, .bellatrix, .capella => false,
            else => true,
        };
    }

    pub fn isPostElectra(self: ForkSeq) bool {
        return switch (self) {
            inline .phase0, .altair, .bellatrix, .capella, .deneb => false,
            else => true,
        };
    }
};

pub fn getForkSeqByForkName(fork_name: []const u8) ForkSeq {
    const values = comptime std.enums.values(ForkSeq);
    inline for (values) |fork_seq| {
        if (std.mem.eql(u8, fork_seq.getForkName(), fork_name)) {
            return fork_seq;
        }
    }

    return ForkSeq.phase0;
}

pub const ForkInfo = struct {
    fork_seq: ForkSeq,
    epoch: Epoch,
    version: Version,
    prev_version: Version,
    prev_fork_seq: ForkSeq,
};

test "fork - getForkName" {
    try std.testing.expectEqualSlices(u8, Fork_Name_Phase0, ForkSeq.phase0.getForkName());
    try std.testing.expectEqualSlices(u8, Fork_Name_Altair, ForkSeq.altair.getForkName());
    try std.testing.expectEqualSlices(u8, Fork_Name_Bellatrix, ForkSeq.bellatrix.getForkName());
    try std.testing.expectEqualSlices(u8, Fork_Name_Capella, ForkSeq.capella.getForkName());
    try std.testing.expectEqualSlices(u8, Fork_Name_Deneb, ForkSeq.deneb.getForkName());
    try std.testing.expectEqualSlices(u8, Fork_Name_Electra, ForkSeq.electra.getForkName());
}

test "fork - getForkSeqByForkName" {
    try std.testing.expect(ForkSeq.phase0 == getForkSeqByForkName(Fork_Name_Phase0));
    try std.testing.expect(ForkSeq.altair == getForkSeqByForkName(Fork_Name_Altair));
    try std.testing.expect(ForkSeq.bellatrix == getForkSeqByForkName(Fork_Name_Bellatrix));
    try std.testing.expect(ForkSeq.capella == getForkSeqByForkName(Fork_Name_Capella));
    try std.testing.expect(ForkSeq.deneb == getForkSeqByForkName(Fork_Name_Deneb));
    try std.testing.expect(ForkSeq.electra == getForkSeqByForkName(Fork_Name_Electra));
}
