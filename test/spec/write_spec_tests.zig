const std = @import("std");
const params = @import("params");
const ForkSeq = params.ForkSeq;
const Preset = params.Preset;
const SpecTestRunner = @import("./test_type/runner.zig").SpecTestRunner;
const test_template = @import("test_templates.zig");
const spec_test_options = @import("spec_test_options");

// Terminology:
//
// File path structure:
// ```
// tests/
//   <preset name>/                     [general, mainnet, minimal]
//     <fork name>/                     [phase0, altair, bellatrix]
//       <test runner name>/            [bls, ssz_static, fork]
//         <test handler name>/         ...
//           <test suite name>/
//             <test case>/<output part>
// ```
//
// Examples
// ```
//       / preset  / fork   / test runner      / test handler / test suite   / test case
//
// tests / general / phase0 / bls              / aggregate    / small        / aggregate_na_signatures/data.yaml
// tests / general / phase0 / ssz_generic      / basic_vector / valid        / vec_bool_1_max/meta.yaml
// tests / mainnet / altair / ssz_static       / Validator    / ssz_random   / case_0/roots.yaml
// tests / mainnet / altair / fork             / fork         / pyspec_tests / altair_fork_random_0/meta.yaml
// tests / minimal / phase0 / operations       / attestation  / pyspec_tests / at_max_inclusion_slot/pre.ssz_snappy
// ```
// Ref: https://github.com/ethereum/consensus-specs/tree/dev/tests/formats#test-structure

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // minimal preset includes many more testcases
    // so use that for generating tests
    const preset = Preset.mainnet;
    const supported_forks = [_]ForkSeq{
        .phase0,
        .altair,
    };
    const supported_test_runners = [_]SpecTestRunner{
        .operations,
    };

    const test_case_dir = "test/spec/test_case/";

    const preset_tests_dir_name = try std.fs.path.join(allocator, &[_][]const u8{
        spec_test_options.spec_test_out_dir,
        spec_test_options.spec_test_version,
        @tagName(preset),
        "tests",
        @tagName(preset),
    });
    defer allocator.free(preset_tests_dir_name);

    inline for (supported_test_runners) |test_runner| {
        const test_case_file = test_case_dir ++ @tagName(test_runner) ++ "_tests.zig";
        const out = try std.fs.cwd().createFile(test_case_file, .{});
        defer out.close();

        const writer = out.writer().any();
        try writeTestCaseHeader(writer, test_runner);

        for (supported_forks) |fork| {
            const test_runner_dir_name = try std.fs.path.join(allocator, &[_][]const u8{
                preset_tests_dir_name,
                @tagName(fork),
                @tagName(test_runner),
            });
            defer allocator.free(test_runner_dir_name);

            const test_handler_dir_names = try listSubdirectories(allocator, &[_][]const u8{test_runner_dir_name});
            defer {
                for (test_handler_dir_names) |el| allocator.free(el);
                allocator.free(test_handler_dir_names);
            }
            const test_suite_dir_names = try listSubdirectories(allocator, test_handler_dir_names);
            defer {
                for (test_suite_dir_names) |el| allocator.free(el);
                allocator.free(test_suite_dir_names);
            }
            const test_case_dir_names = try listSubdirectories(allocator, test_suite_dir_names);
            defer {
                for (test_case_dir_names) |el| allocator.free(el);
                allocator.free(test_case_dir_names);
            }

            for (test_case_dir_names) |test_case_dir_name| {
                var split_it = std.mem.splitBackwardsSequence(u8, test_case_dir_name, "/");
                const test_case_name = split_it.next().?;
                _ = split_it.next();
                const test_handler_name = split_it.next().?;

                try writeTestCase(writer, fork, test_runner, test_handler_name, test_case_name, test_case_dir_name);
            }
        }
    }
}

// List all subdirectories for each directory in `directory_names`. The result is a list
// of subdirectory paths that join with `directory_names`
fn listSubdirectories(allocator: std.mem.Allocator, directory_names: []const []const u8) ![][]const u8 {
    var subdirectories = std.ArrayList([]const u8).init(allocator);
    errdefer {
        for (subdirectories.items) |el| allocator.free(el);
        subdirectories.deinit();
    }

    for (directory_names) |directory_name| {
        var directory = try std.fs.cwd().openDir(directory_name, .{ .iterate = true });
        defer directory.close();
        var it = directory.iterate();
        while (try it.next()) |entry| {
            if (entry.kind == .directory) {
                try subdirectories.append(try std.fs.path.join(allocator, &[_][]const u8{
                    directory_name,
                    entry.name,
                }));
            }
        }
    }

    return subdirectories.toOwnedSlice();
}

fn writeTestCaseHeader(writer: std.io.AnyWriter, test_runner: SpecTestRunner) !void {
    var header: []const u8 = undefined;

    switch (test_runner) {
        .operations => {
            header = test_template.OPERATIONS_HEADER;
        },
        else => {
            return error.UnsupportedTestRunner;
        },
    }

    try writer.writeAll(header);
}

fn writeTestCase(
    writer: std.io.AnyWriter,
    fork: ForkSeq,
    test_runner: SpecTestRunner,
    test_handler: []const u8,
    test_case: []const u8,
    test_case_dir_name: []const u8,
) !void {
    switch (test_runner) {
        .operations => {
            try writer.print(test_template.OPERATIONS_TEST_TEMPLATE, .{ @tagName(fork), @tagName(test_runner), test_handler, test_case, test_case_dir_name, @tagName(fork), test_handler });
        },
        else => {
            return error.UnsupportedTestRunner;
        },
    }
}
