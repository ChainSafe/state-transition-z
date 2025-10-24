const ssz = @import("consensus_types");
const Root = ssz.primitive.Root.Type;
const ForkSeq = @import("config").ForkSeq;
const Preset = @import("preset").Preset;
const preset = @import("preset").preset;
const std = @import("std");
const state_transition = @import("state_transition");
const TestCachedBeaconStateAllForks = state_transition.test_utils.TestCachedBeaconStateAllForks;
const BeaconStateAllForks = state_transition.BeaconStateAllForks;
const Withdrawals = ssz.capella.Withdrawals.Type;
const WithdrawalsResult = state_transition.WithdrawalsResult;
const test_case = @import("../test_case.zig");
const loadSszValue = test_case.loadSszSnappyValue;
const loadBlsSetting = test_case.loadBlsSetting;
const expectEqualBeaconStates = test_case.expectEqualBeaconStates;
const BlsSetting = test_case.BlsSetting;

/// See https://github.com/ethereum/consensus-specs/tree/master/tests/formats/operations#operations-tests
pub const Operation = enum {
    attestation,
    attester_slashing,
    block_header,
    bls_to_execution_change,
    consolidation_request,
    deposit,
    deposit_request,
    execution_payload,
    proposer_slashing,
    sync_aggregate,
    voluntary_exit,
    withdrawal_request,
    withdrawals,

    pub fn inputName(self: Operation) []const u8 {
        return switch (self) {
            .block_header => "block",
            .bls_to_execution_change => "address_change",
            .execution_payload => "body",
            .withdrawals => "execution_payload",
            else => @tagName(self),
        };
    }

    pub fn operationObject(self: Operation) []const u8 {
        return switch (self) {
            .attestation => "Attestation",
            .attester_slashing => "AttesterSlashing",
            .block_header => "BeaconBlock",
            .bls_to_execution_change => "SignedBLSToExecutionChange",
            .consolidation_request => "ConsolidationRequest",
            .deposit => "Deposit",
            .deposit_request => "DepositRequest",
            .execution_payload => "BeaconBlockBody",
            .proposer_slashing => "ProposerSlashing",
            .sync_aggregate => "SyncAggregate",
            .voluntary_exit => "SignedVoluntaryExit",
            .withdrawal_request => "WithdrawalRequest",
            .withdrawals => "ExecutionPayload",
        };
    }

    pub fn suiteName(self: Operation) []const u8 {
        return @tagName(self) ++ "/pyspec_tests";
    }
};

pub const Handler = Operation;

pub fn TestCase(comptime fork: ForkSeq, comptime operation: Operation, comptime valid: bool) type {
    const ForkTypes = @field(ssz, fork.forkName());
    const OpType = @field(ForkTypes, operation.operationObject());

    return struct {
        pre: TestCachedBeaconStateAllForks,
        post: if (valid) BeaconStateAllForks else void,
        op: OpType.Type,
        bls_setting: BlsSetting,

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
                .op = OpType.default_value,
                .bls_setting = loadBlsSetting(allocator, dir),
            };
            // init the op

            try loadSszValue(OpType, allocator, dir, comptime operation.inputName() ++ ".ssz_snappy", &tc.op);
            errdefer {
                if (comptime @hasDecl(OpType, "deinit")) {
                    OpType.deinit(allocator, &tc.op);
                }
            }

            // init the pre state

            const pre_state = try allocator.create(ForkTypes.BeaconState.Type);
            errdefer {
                ForkTypes.BeaconState.deinit(allocator, pre_state);
                allocator.destroy(pre_state);
            }
            pre_state.* = ForkTypes.BeaconState.default_value;
            try loadSszValue(ForkTypes.BeaconState, allocator, dir, "pre.ssz_snappy", pre_state);

            var pre_state_all_forks = try BeaconStateAllForks.init(fork, pre_state);

            tc.pre = try TestCachedBeaconStateAllForks.initFromState(allocator, &pre_state_all_forks, fork, pre_state_all_forks.fork().epoch);

            // init the post state if this is a "valid" test case

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
            if (comptime @hasDecl(OpType, "deinit")) {
                OpType.deinit(self.pre.allocator, &self.op);
            }
            self.pre.deinit();
            if (valid) {
                self.post.deinit(self.pre.allocator);
            }
        }

        pub fn process(self: *Self) !void {
            const verify = self.bls_setting.verify();

            switch (operation) {
                .attestation => {
                    const attestations_fork: ForkSeq = if (fork.gte(.electra)) .electra else .phase0;
                    var attestations = @field(ssz, attestations_fork.forkName()).Attestations.default_value;
                    defer attestations.deinit(self.pre.allocator);
                    const attestation: *@field(ssz, attestations_fork.forkName()).Attestation.Type = @ptrCast(@alignCast(&self.op));
                    try attestations.append(self.pre.allocator, attestation.*);
                    const atts = attestations;
                    const attestations_wrapper: state_transition.Attestations = if (fork.gte(.electra))
                        .{ .electra = &atts }
                    else
                        .{ .phase0 = &atts };

                    try state_transition.processAttestations(self.pre.allocator, self.pre.cached_state, attestations_wrapper, verify);
                },
                .attester_slashing => {
                    try state_transition.processAttesterSlashing(OpType.Type, self.pre.cached_state, &self.op, verify);
                },
                .block_header => {
                    return error.SkipZigTest;
                    // TODO: processBlockHeader currently takes signed block which is incorrect. Wait for it to accept unsigned block.
                    // try state_transition.processBlockHeader(self.pre.allocator, self.pre.cached_state, &self.op);
                },
                .bls_to_execution_change => {
                    try state_transition.processBlsToExecutionChange(self.pre.cached_state, &self.op);
                },
                .consolidation_request => {
                    try state_transition.processConsolidationRequest(self.pre.allocator, self.pre.cached_state, &self.op);
                },
                .deposit => {
                    try state_transition.processDeposit(self.pre.allocator, self.pre.cached_state, &self.op);
                },
                .deposit_request => {
                    try state_transition.processDepositRequest(self.pre.allocator, self.pre.cached_state, &self.op);
                },
                .execution_payload => {
                    try state_transition.processExecutionPayload(
                        self.pre.allocator,
                        self.pre.cached_state,
                        .{ .regular = @unionInit(state_transition.BeaconBlockBody, @tagName(fork), &self.op) },
                        .{ .data_availability_status = .available, .execution_payload_status = if (valid) .valid else .invalid },
                    );
                },
                .proposer_slashing => {
                    try state_transition.processProposerSlashing(self.pre.cached_state, &self.op, verify);
                },
                .sync_aggregate => {
                    return error.SkipZigTest;
                },
                .voluntary_exit => {
                    try state_transition.processVoluntaryExit(self.pre.cached_state, &self.op, verify);
                },
                .withdrawal_request => {
                    try state_transition.processWithdrawalRequest(self.pre.allocator, self.pre.cached_state, &self.op);
                },
                .withdrawals => {
                    var withdrawals_result = WithdrawalsResult{
                        .withdrawals = try Withdrawals.initCapacity(
                            self.pre.allocator,
                            preset.MAX_WITHDRAWALS_PER_PAYLOAD,
                        ),
                    };

                    var withdrawal_balances = std.AutoHashMap(u64, usize).init(self.pre.allocator);
                    defer withdrawal_balances.deinit();

                    try state_transition.getExpectedWithdrawals(self.pre.allocator, &withdrawals_result, &withdrawal_balances, self.pre.cached_state);
                    defer withdrawals_result.withdrawals.deinit(self.pre.allocator);

                    var payload_withdrawals_root: Root = undefined;
                    // self.op is ExecutionPayload in this case
                    try ssz.capella.Withdrawals.hashTreeRoot(self.pre.allocator, &self.op.withdrawals, &payload_withdrawals_root);

                    try state_transition.processWithdrawals(self.pre.allocator, self.pre.cached_state, withdrawals_result, payload_withdrawals_root);
                },
            }
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
