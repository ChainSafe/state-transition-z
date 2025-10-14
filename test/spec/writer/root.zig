const std = @import("std");
const ForkSeq = @import("config").ForkSeq;
const SpecTestRunner = @import("../test_type/runner.zig").SpecTestRunner;
const writeOperationsTests = @import("./operations.zig").writeOperationsTests;

pub fn writeTests(comptime forks: []const ForkSeq, comptime runner: SpecTestRunner, writer: std.io.AnyWriter) !void {
    switch (runner) {
        .operations => try writeOperationsTests(forks, writer),
        else => {
            @compileError("Unsupported test runner");
        },
    }
}
