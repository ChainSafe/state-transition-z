const std = @import("std");
const ssz = @import("consensus_types");
const ForkSeq = @import("config").ForkSeq;
const Preset = @import("preset").Preset;
const state_transition = @import("state_transition");
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const BeaconStateAllForks = state_transition.BeaconStateAllForks;
const test_case = @import("../test_case.zig");
const loadSszValue = test_case.loadSszSnappyValue;
const expectEqualBeaconStates = test_case.expectEqualBeaconStates;

/// https://github.com/ethereum/consensus-specs/blob/master/tests/formats/sanity/README.md
pub const Handler = enum {
    /// https://github.com/ethereum/consensus-specs/blob/master/tests/formats/sanity/blocks.md
    blocks,
    /// https://github.com/ethereum/consensus-specs/blob/master/tests/formats/sanity/slots.md
    slots,

    pub fn suiteName(self: Handler) []const u8 {
        return @tagName(self) ++ "/pyspec_tests";
    }
};

pub const handlers = std.enums.values(Handler);

pub fn SlotsTestCase(comptime fork: ForkSeq) type {
    const ForkTypes = @field(ssz, fork.forkName());

    return struct {
        pre: TestCachedBeaconStateAllForks,
        post: BeaconStateAllForks,
        slots: u64,

        const Self = @This();

        pub fn execute(allocator: std.mem.Allocator, dir: std.fs.Dir) !void {
            var tc = try Self.init(allocator, dir);
            defer tc.deinit();

            try tc.runTest();
        }

        pub fn init(allocator: std.mem.Allocator, dir: std.fs.Dir) !Self {
            var tc = Self{
                .pre = undefined,
                .post = undefined,
                .slots = 0,
            };

            // Load slots
            var slots_file = try dir.openFile("slots.yaml", .{});
            defer slots_file.close();
            const slots_content = try slots_file.readToEndAlloc(allocator, 1024);
            defer allocator.free(slots_content);
            // Parse YAML for slots (simplified; assume single value)
            tc.slots = std.fmt.parseInt(u64, std.mem.trim(u8, slots_content, " \n"), 10) catch 0;

            // Load pre state
            const pre_state = try allocator.create(ForkTypes.BeaconState.Type);
            errdefer {
                ForkTypes.BeaconState.deinit(allocator, pre_state);
                allocator.destroy(pre_state);
            }
            pre_state.* = ForkTypes.BeaconState.default_value;
            try loadSszValue(ForkTypes.BeaconState, allocator, dir, "pre.ssz_snappy", pre_state);

            var pre_state_all_forks = try BeaconStateAllForks.init(fork, pre_state);
            tc.pre = try TestCachedBeaconStateAllForks.initFromState(allocator, &pre_state_all_forks);

            // Load post state
            const post_state = try allocator.create(ForkTypes.BeaconState.Type);
            errdefer {
                ForkTypes.BeaconState.deinit(allocator, post_state);
                allocator.destroy(post_state);
            }
            post_state.* = ForkTypes.BeaconState.default_value;
            try loadSszValue(ForkTypes.BeaconState, allocator, dir, "post.ssz_snappy", post_state);
            tc.post = try BeaconStateAllForks.init(fork, post_state);

            return tc;
        }

        pub fn deinit(self: *Self) void {
            self.pre.deinit();
            self.post.deinit(self.pre.allocator);
        }

        pub fn process(self: *Self) !void {
            try state_transition.state_transition.processSlotsWithTransientCache(
                self.pre.allocator,
                self.pre.cached_state,
                self.pre.cached_state.state.slot() + self.slots,
                undefined,
            );
        }

        pub fn runTest(self: *Self) !void {
            try self.process();
            try expectEqualBeaconStates(self.post, self.pre.cached_state.state.*);
        }
    };
}

pub fn BlocksTestCase(comptime fork: ForkSeq, comptime valid: bool) type {
    const ForkTypes = @field(ssz, fork.forkName());
    const SignedBeaconBlock = @field(ForkTypes, "SignedBeaconBlock");

    return struct {
        pre: TestCachedBeaconStateAllForks,
        post: if (valid) BeaconStateAllForks else void,
        blocks: []SignedBeaconBlock.Type,

        const Self = @This();

        pub fn execute(allocator: std.mem.Allocator, dir: std.fs.Dir) !void {
            var tc = try Self.init(allocator, dir);
            defer tc.deinit();

            try tc.runTest();
        }

        pub fn init(allocator: std.mem.Allocator, dir: std.fs.Dir) !Self {
            var tc = Self{
                .pre = undefined,
                .post = undefined,
                .blocks = undefined,
            };

            // Load meta.yaml for blocks_count
            var meta_file = try dir.openFile("meta.yaml", .{});
            defer meta_file.close();
            const meta_content = try meta_file.readToEndAlloc(allocator, 1024);
            defer allocator.free(meta_content);
            // Parse YAML for blocks_count (simplified; assume "blocks_count: N")
            const blocks_count_str = std.mem.trim(u8, meta_content, " \n{}");
            const blocks_count = if (std.mem.indexOf(u8, blocks_count_str, "blocks_count: ")) |start| blk: {
                const num_str = blocks_count_str[start + "blocks_count: ".len ..];
                break :blk std.fmt.parseInt(usize, std.mem.trim(u8, num_str, " "), 10) catch 1;
            } else 1;

            // Load pre state
            const pre_state = try allocator.create(ForkTypes.BeaconState.Type);
            errdefer {
                ForkTypes.BeaconState.deinit(allocator, pre_state);
                allocator.destroy(pre_state);
            }
            pre_state.* = ForkTypes.BeaconState.default_value;
            try loadSszValue(ForkTypes.BeaconState, allocator, dir, "pre.ssz_snappy", pre_state);

            var pre_state_all_forks = try BeaconStateAllForks.init(fork, pre_state);
            tc.pre = try TestCachedBeaconStateAllForks.initFromState(allocator, &pre_state_all_forks);

            // Load blocks
            tc.blocks = try allocator.alloc(SignedBeaconBlock.Type, blocks_count);
            errdefer {
                for (tc.blocks) |*block| {
                    SignedBeaconBlock.deinit(allocator, block);
                }
                allocator.free(tc.blocks);
            }
            for (tc.blocks, 0..) |*block, i| {
                block.* = SignedBeaconBlock.default_value;
                const block_filename = try std.fmt.allocPrint(allocator, "block_{d}.ssz_snappy", .{i});
                defer allocator.free(block_filename);
                try loadSszValue(SignedBeaconBlock, allocator, dir, block_filename, block);
            }

            // Load post state if valid
            if (valid) {
                const post_state = try allocator.create(ForkTypes.BeaconState.Type);
                errdefer {
                    ForkTypes.BeaconState.deinit(allocator, post_state);
                    allocator.destroy(post_state);
                }
                post_state.* = ForkTypes.BeaconState.default_value;
                try loadSszValue(ForkTypes.BeaconState, allocator, dir, "post.ssz_snappy", post_state);
                tc.post = try BeaconStateAllForks.init(fork, post_state);
            }

            return tc;
        }

        pub fn deinit(self: *Self) void {
            for (self.blocks) |*block| {
                if (comptime @hasDecl(SignedBeaconBlock, "deinit")) {
                    SignedBeaconBlock.deinit(self.pre.allocator, block);
                }
            }
            self.pre.allocator.free(self.blocks);
            self.pre.deinit();
            if (valid) {
                self.post.deinit(self.pre.allocator);
            }
        }

        pub fn process(self: *Self) !void {
            var state = self.pre.cached_state;
            for (self.blocks) |*block| {
                const signed_block = @unionInit(state_transition.SignedBeaconBlock, @tagName(fork), block);
                state = try state_transition.state_transition.stateTransition(
                    self.pre.allocator,
                    state,
                    .{
                        .regular = &signed_block,
                    },
                    .{},
                );
            }
            self.pre.cached_state = state;
        }

        pub fn runTest(self: *Self) !void {
            if (valid) {
                try self.process();
                try expectEqualBeaconStates(self.post, self.pre.cached_state.state.*);
            } else {
                self.process() catch |err| {
                    if (err == error.SkipZigTest) {
                        return err;
                    }
                    return;
                };
                return error.ExpectedError;
            }
        }
    };
}
