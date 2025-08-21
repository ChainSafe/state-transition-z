const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    const dep_ssz = b.dependency("ssz", .{});
    const dep_blst_z = b.dependency("blst_z", .{});

    const module_ssz = dep_ssz.module("ssz");
    const module_consensus_types = dep_ssz.module("consensus_types");
    const module_blst_min_pk = dep_blst_z.module("blst_min_pk");

    const options_build_options = b.addOptions();
    const option_preset = b.option([]const u8, "preset", "") orelse "mainnet";
    options_build_options.addOption([]const u8, "preset", option_preset);
    const options_module_build_options = options_build_options.createModule();

    const module_hex = b.createModule(.{
        .root_source_file = b.path("src/hex.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.modules.put(b.dupe("hex"), module_hex) catch @panic("OOM");

    const module_params = b.createModule(.{
        .root_source_file = b.path("src/params/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module_params.addImport("hex", module_hex);
    module_params.addImport("ssz", module_ssz);
    module_params.addImport("consensus_types", module_consensus_types);
    module_params.addImport("build_options", options_module_build_options);
    b.modules.put(b.dupe("params"), module_params) catch @panic("OOM");

    const module_config = b.createModule(.{
        .root_source_file = b.path("src/config/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module_config.addImport("hex", module_hex);
    module_config.addImport("ssz", module_ssz);
    module_config.addImport("consensus_types", module_consensus_types);
    module_config.addImport("params", module_params);
    b.modules.put(b.dupe("config"), module_config) catch @panic("OOM");

    const module_state_transition = b.createModule(.{
        .root_source_file = b.path("src/state_transition/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module_state_transition.addImport("ssz", module_ssz);
    module_state_transition.addImport("consensus_types", module_consensus_types);
    module_state_transition.addImport("blst_min_pk", module_blst_min_pk);
    module_state_transition.addImport("config", module_config);
    module_state_transition.addImport("params", module_params);
    b.modules.put(b.dupe("state_transition"), module_state_transition) catch @panic("OOM");

    const lib = b.addStaticLibrary(.{
        .name = "state-transition",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/state_transition/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.root_module.addImport("state_transition", module_state_transition);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "state-transition",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    const sharedLib = b.addSharedLibrary(.{
        .name = "state-transition-utils",
        .root_source_file = b.path("src/state_transition/root_c_abi.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(sharedLib);

    // need libc for threading capability
    sharedLib.linkLibC();

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const shared_lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/state_transition/root_c_abi.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_shared_lib_unit_tests = b.addRunArtifact(shared_lib_unit_tests);

    const params_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/params/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    params_unit_tests.root_module.addImport("build_options", options_module_build_options);
    params_unit_tests.root_module.addImport("hex", module_hex);
    params_unit_tests.root_module.addImport("ssz", module_ssz);
    params_unit_tests.root_module.addImport("consensus_types", module_consensus_types);

    const run_params_unit_tests = b.addRunArtifact(params_unit_tests);

    const config_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/config/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    config_unit_tests.root_module.addImport("hex", module_hex);
    config_unit_tests.root_module.addImport("ssz", module_ssz);
    config_unit_tests.root_module.addImport("consensus_types", module_consensus_types);
    config_unit_tests.root_module.addImport("params", module_params);

    const run_config_unit_tests = b.addRunArtifact(config_unit_tests);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const state_transition_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/state_transition/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    state_transition_unit_tests.root_module.addImport("ssz", module_ssz);
    state_transition_unit_tests.root_module.addImport("consensus_types", module_consensus_types);
    state_transition_unit_tests.root_module.addImport("blst_min_pk", module_blst_min_pk);
    state_transition_unit_tests.root_module.addImport("config", module_config);
    state_transition_unit_tests.root_module.addImport("params", module_params);

    const run_state_transition_unit_tests = b.addRunArtifact(state_transition_unit_tests);

    // common test utils module used for different kinds of tests, like int, perf etc.
    const test_utils = b.createModule(.{
        .root_source_file = b.path("test/utils/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_utils.addImport("ssz", module_ssz);
    test_utils.addImport("consensus_types", module_consensus_types);
    test_utils.addImport("blst_min_pk", module_blst_min_pk);
    test_utils.addImport("config", module_config);
    test_utils.addImport("state_transition", module_state_transition);

    const test_utils_tests = b.addTest(.{
        .name = "utils",
        .root_module = test_utils,
        .filters = &[_][]const u8{},
    });
    const run_test_utils_tests = b.addRunArtifact(test_utils_tests);

    const module_test_int = b.createModule(.{
        .root_source_file = b.path("test/int/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module_test_int.addImport("config", module_config);
    module_test_int.addImport("state_transition", module_state_transition);
    module_test_int.addImport("ssz", dep_ssz.module("ssz"));
    module_test_int.addImport("consensus_types", module_consensus_types);
    module_test_int.addImport("blst_min_pk", module_blst_min_pk);
    module_test_int.addImport("test_utils", test_utils);

    const test_int_tests = b.addTest(.{
        .name = "int",
        .root_module = module_test_int,
        .filters = &[_][]const u8{},
    });

    const run_test_int_tests = b.addRunArtifact(test_int_tests);

    // trigger via `zig build test:unit`
    const test_step = b.step("test:unit", "Run unit tests");
    test_step.dependOn(&run_params_unit_tests.step);
    test_step.dependOn(&run_config_unit_tests.step);
    test_step.dependOn(&run_state_transition_unit_tests.step);
    test_step.dependOn(&run_shared_lib_unit_tests.step);

    // trigger via `zig build test:int`
    const test_step_int = b.step("test:int", "Run int tests");
    test_step_int.dependOn(&run_test_int_tests.step);
    // this also run tests inside test utils
    test_step_int.dependOn(&run_test_utils_tests.step);
}
