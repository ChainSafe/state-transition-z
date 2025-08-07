const std = @import("std");
const Allocator = std.mem.Allocator;

const ssz = @import("consensus_types");
const preset = ssz.preset;
const Root = ssz.primitive.Root.Type;
const ZERO_HASH = @import("../constants.zig").ZERO_HASH;

const ExecutionPayload = @import("types/execution_payload.zig").ExecutionPayload;

const Slot = ssz.primitive.Slot.Type;

const CachedBeaconStateAllForks = @import("cache/state_cache.zig").CachedBeaconStateAllForks;
pub const SignedBeaconBlock = @import("types/beacon_block.zig").SignedBeaconBlock;
const verifyProposerSignature = @import("./signature_sets/proposer.zig").verifyProposerSignature;
const processBlock = @import("./block/process_block.zig").processBlock;
const BlockExternalData = @import("./block/external_data.zig").BlockExternalData;
const BeaconBlock = @import("types/beacon_block.zig").BeaconBlock;
const SignedVoluntaryExit = ssz.phase0.SignedVoluntaryExit.Type;
const Deposit = ssz.phase0.Deposit.Type;
const DepositRequest = ssz.electra.DepositRequest.Type;
const Attestation = @import("types/attestation.zig").Attestation;
const Attestations = @import("types/attestation.zig").Attestations;
const SignedBLSToExecutionChange = ssz.capella.SignedBLSToExecutionChange.Type;
const AttesterSlashings = @import("types/attester_slashing.zig").AttesterSlashings;
const ProposerSlashing = ssz.phase0.ProposerSlashing.Type;
const BlindedBeaconBlock = @import("types/beacon_block.zig").BlindedBeaconBlock;
const BlindedBeaconBlockBody = @import("types/beacon_block.zig").BlindedBeaconBlockBody;
const BeaconBlockBody = @import("types/beacon_block.zig").BeaconBlockBody;
const SignedBlindedBeaconBlock = @import("types/beacon_block.zig").SignedBlindedBeaconBlock;
const TestCachedBeaconStateAllForks = @import("../../test/int/generate_state.zig").TestCachedBeaconStateAllForks;
const EpochTransitionCacheOpts = @import("cache/epoch_transition_cache.zig").EpochTransitionCacheOpts;
const EpochTransitionCache = @import("cache/epoch_transition_cache.zig").EpochTransitionCache;
const process_epoch = @import("epoch/process_epoch.zig").process_epoch;
const computeEpochAtSlot = @import("utils/epoch.zig").computeEpochAtSlot;
const processSlot = @import("slot/process_slot.zig").processSlot;

const Options = struct {
    verify_state_root: bool = true,
    verify_proposer: bool = true,
    verify_signatures: bool = false,
    do_not_transfer_cache: bool = false,
};

pub const Block = union(enum) {
    block: BeaconBlock,
    blinded_block: BlindedBeaconBlock,
};

pub const SignedBlock = union(enum) {
    signed_beacon_block: *const SignedBeaconBlock,
    signed_blinded_beacon_block: *const SignedBlindedBeaconBlock,

    pub const BeaconBlockBody_ = union(enum) {
        unblinded: BeaconBlockBody,
        blinded: BlindedBeaconBlockBody,

        pub fn blobKzgCommitmentsLen(self: *const BeaconBlockBody_) usize {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getBlobKzgCommitments().items.len,
            };
        }

        pub fn getEth1Data(self: *const BeaconBlockBody_) *const ssz.phase0.Eth1Data.Type {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getEth1Data(),
            };
        }

        pub fn getRandaoReveal(self: *const BeaconBlockBody_) ssz.primitive.BLSSignature.Type {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getRandaoReveal(),
            };
        }

        pub fn deposits(self: *const BeaconBlockBody_) []Deposit {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getDeposits(),
            };
        }
        pub fn depositRequests(self: *const BeaconBlockBody_) []DepositRequest {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getDepositRequests(),
            };
        }

        pub fn attesterSlashings(self: *const BeaconBlockBody_) AttesterSlashings {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getAttesterSlashings(),
            };
        }

        pub fn attestations(self: *const BeaconBlockBody_) Attestations {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getAttestations(),
            };
        }

        pub fn voluntaryExits(self: *const BeaconBlockBody_) []SignedVoluntaryExit {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getVoluntaryExits(),
            };
        }

        pub fn proposerSlashings(self: *const BeaconBlockBody_) []ProposerSlashing {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getProposerSlashings(),
            };
        }

        pub fn blsToExecutionChanges(self: *const BeaconBlockBody_) []SignedBLSToExecutionChange {
            return switch (self.*) {
                inline .unblinded, .blinded => |b| b.getBlsToExecutionChanges(),
            };
        }
    };

    pub fn getMessage(self: *const SignedBlock) Block {
        return switch (self.*) {
            .signed_beacon_block => |b| .{ .block = b.getBeaconBlock() },
            .signed_blinded_beacon_block => |b| .{ .blinded_block = b.getBeaconBlock() },
        };
    }
    pub fn getBeaconBlockBody(self: *const SignedBlock) BeaconBlockBody_ {
        return switch (self.*) {
            .signed_beacon_block => |b| .{ .unblinded = b.getBeaconBlock().getBeaconBlockBody() },
            .signed_blinded_beacon_block => |b| .{ .blinded = b.getBeaconBlock().getBeaconBlockBody() },
        };
    }

    pub fn getParentRoot(self: *const SignedBlock) [32]u8 {
        return switch (self.*) {
            .signed_beacon_block => |b| b.getBeaconBlock().getParentRoot(),
            .signed_blinded_beacon_block => |b| b.getBeaconBlock().getParentRoot(),
        };
    }

    pub fn getStateRoot(self: *const SignedBlock) [32]u8 {
        return switch (self.*) {
            .signed_beacon_block => |b| b.getBeaconBlock().getStateRoot(),
            .signed_blinded_beacon_block => |b| b.getBeaconBlock().getStateRoot(),
        };
    }

    pub fn getSlot(self: *const SignedBlock) Slot {
        return switch (self.*) {
            .signed_beacon_block => |b| b.getBeaconBlock().getSlot(),
            .signed_blinded_beacon_block => |b| b.getBeaconBlock().getSlot(),
        };
    }

    pub fn hashTreeRoot(self: *const SignedBlock, allocator: std.mem.Allocator, out: *[32]u8) !void {
        return switch (self.*) {
            .signed_beacon_block => |b| b.getBeaconBlock().hashTreeRoot(allocator, out),
            .signed_blinded_beacon_block => |b| b.getBeaconBlock().hashTreeRoot(allocator, out),
        };
    }

    pub fn getProposerIndex(self: *const SignedBlock) u64 {
        return switch (self.*) {
            .signed_beacon_block => |b| b.getBeaconBlock().getProposerIndex(),
            .signed_blinded_beacon_block => |b| b.getBeaconBlock().getProposerIndex(),
        };
    }

    pub fn getSignature(self: *const SignedBlock) ssz.primitive.BLSSignature.Type {
        return switch (self.*) {
            .signed_beacon_block => |b| b.getSignature(),
            .signed_blinded_beacon_block => |b| b.getSignature(),
        };
    }
};

fn processSlotsWithTransientCache(
    allocator: std.mem.Allocator,
    post_state: *CachedBeaconStateAllForks,
    slot: Slot,
    _: EpochTransitionCacheOpts,
) !void {
    var post_state_slot = post_state.state.getSlot();
    if (post_state_slot > slot) return error.outdatedSlot;

    while (post_state_slot < slot) {
        try processSlot(allocator, post_state);

        if ((post_state_slot + 1) % preset.SLOTS_PER_EPOCH == 0) {
            _ = post_state.config.getForkSeq(post_state_slot);
            // TODO(bing): implement
            // const epochTransitionTimer = metrics?.epochTransitionTime.startTimer();
            // var epoch_transition_cache = beforeProcessEpoch(post_state, epoch_transition_cache_opts);
            // process_epoch(allocator, post_state, epoch_transition_cache);

            // registerValidatorStatuses

            post_state_slot += 1;

            // afterProcessEpoch
            // post_state.commit
        }

        //epochTransitionTimer
        // upgrade state
        _ = computeEpochAtSlot(post_state_slot);
        _ = post_state.config;

        //TODO(bing): upgradeState to forks
        //switch (true) {
        //    state_epoch == config.chain.DENEB_FORK_EPOCH => post_state = upgradeState();
        //
        //}
    }
}

pub fn stateTransition(
    allocator: std.mem.Allocator,
    state: *CachedBeaconStateAllForks,
    signed_block: SignedBlock,
    opts: Options,
) !*CachedBeaconStateAllForks {
    const block = signed_block.getMessage();
    const block_slot = switch (block) {
        .block => |b| b.getSlot(),
        .blinded_block => |b| b.getSlot(),
    };

    //TODO(bing): deep clone
    // const post_state = state.clone();
    const post_state = state;

    //TODO(bing): metrics
    //if (metrics) {
    //  onStateCloneMetrics(postState, metrics, StateCloneSource.stateTransition);
    //}

    try processSlotsWithTransientCache(allocator, post_state, block_slot, .{});

    // Verify proposer signature only
    if (opts.verify_proposer and !try verifyProposerSignature(post_state, &signed_block)) {
        return error.InvalidBlockSignature;
    }

    //  // Note: time only on success
    //  const processBlockTimer = metrics?.processBlockTime.startTimer();
    //
    try processBlock(
        allocator,
        post_state,
        &signed_block,
        BlockExternalData{
            .execution_payload_status = .valid,
            .data_availability_status = .available,
        },
        .{},
    );
    //
    // TODO(bing): commit
    //  const processBlockCommitTimer = metrics?.processBlockCommitTime.startTimer();
    //  postState.commit();
    //  processBlockCommitTimer?.();

    //  // Note: time only on success. Include processBlock and commit
    //  processBlockTimer?.();
    // TODO(bing): metrics
    //  if (metrics) {
    //    onPostStateMetrics(postState, metrics);
    //  }

    // Verify state root
    if (opts.verify_state_root) {
        var out: [32]u8 = undefined;
        //    const hashTreeRootTimer = metrics?.stateHashTreeRootTime.startTimer({
        //      source: StateHashTreeRootSource.stateTransition,
        //    });
        try post_state.state.hashTreeRoot(allocator, &out);
        //    hashTreeRootTimer?.();

        const block_state_root = switch (block) {
            .block => |b| b.getStateRoot(),
            .blinded_block => |b| b.getStateRoot(),
        };
        if (!std.mem.eql(u8, &out, block_state_root)) {
            return error.InvalidStateRoot;
        }
    }

    return state;
}
