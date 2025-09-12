const std = @import("std");

const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const DIM = "\x1b[2m";
const RESET = "\x1b[0m";

pub const TestLogger = struct {
    total: usize = 0,
    failed: usize = 0,
    skipped: usize = 0,

    pub fn run(self: *TestLogger, comptime name: []const u8, body: anytype) !void {
        self.total += 1;

        // announce what's running
        std.debug.print("{s}→ {s}{s}\n", .{ DIM, name, RESET });

        body() catch |e| {
            self.failed += 1;
            std.debug.print("{s}❌ FAIL{s} {s}\n", .{ RED, RESET, name });

            return e;
        };

        std.debug.print("{s}✅ PASS{s} {s}\n", .{ GREEN, RESET, name });
    }

    pub fn summary(self: *const TestLogger, comptime banner: []const u8) void {
        const passed = self.total - self.failed - self.skipped;
        std.debug.print(
            "\n===== {s} SUMMARY =====\nTotal: {d}\nPassed: {d}\nFailed: {d}\nSkipped: {d}\n========================\n",
            .{ banner, self.total, passed, self.failed, self.skipped },
        );
    }
};
