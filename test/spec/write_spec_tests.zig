const std = @import("std");
const ForkSeq = @import("config").ForkSeq;
const SpecTestRunner = @import("./test_type/runner.zig").SpecTestRunner;
const writeTests = @import("./writer/root.zig").writeTests;

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
    const supported_forks = [_]ForkSeq{
        .phase0,
        .altair,
        .bellatrix,
        .capella,
        .deneb,
        .electra,
    };
    const supported_test_runners = [_]SpecTestRunner{
        .operations,
    };

    const test_case_dir = "test/spec/test_case/";

    inline for (supported_test_runners) |test_runner| {
        const test_case_file = test_case_dir ++ @tagName(test_runner) ++ "_tests.zig";
        const out = try std.fs.cwd().createFile(test_case_file, .{});
        defer out.close();

        const writer = out.writer().any();
        try writeTests(&supported_forks, test_runner, writer);
    }
}
