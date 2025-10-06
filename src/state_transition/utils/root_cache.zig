const std = @import("std");
const Allocator = std.mem.Allocator;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const getBlockRootFn = @import("../utils/block_root.zig").getBlockRoot;
const getBlockRootAtSlotFn = @import("../utils/block_root.zig").getBlockRootAtSlot;
const ssz = @import("consensus_types");
const Checkpoint = ssz.phase0.Checkpoint.Type;
const Epoch = ssz.primitive.Epoch.Type;
const Slot = ssz.primitive.Slot.Type;
const Root = ssz.primitive.Root.Type;

pub const RootCache = struct {
    allocator: Allocator,
    current_justified_checkpoint: Checkpoint,
    previous_justified_checkpoint: Checkpoint,
    state: *const BeaconStateAllForks,
    block_root_epoch_cache: std.AutoHashMap(Epoch, Root),
    block_root_slot_cache: std.AutoHashMap(Slot, Root),

    pub fn init(allocator: Allocator, cached_state: *const CachedBeaconStateAllForks) !*RootCache {
        const instance = try allocator.create(RootCache);
        const state = cached_state.state;
        instance.* = RootCache{
            .allocator = allocator,
            .current_justified_checkpoint = state.currentJustifiedCheckpoint().*,
            .previous_justified_checkpoint = state.previousJustifiedCheckpoint().*,
            .state = state,
            .block_root_epoch_cache = std.AutoHashMap(Epoch, Root).init(allocator),
            .block_root_slot_cache = std.AutoHashMap(Slot, Root).init(allocator),
        };

        return instance;
    }

    pub fn getBlockRoot(self: *RootCache, epoch: Epoch) !Root {
        if (self.block_root_epoch_cache.get(epoch)) |root| {
            return root;
        } else {
            const root = try getBlockRootFn(self.state, epoch);
            try self.block_root_epoch_cache.put(epoch, root);
            return root;
        }
    }

    pub fn getBlockRootAtSlot(self: *RootCache, slot: Slot) !Root {
        if (self.block_root_slot_cache.get(slot)) |root| {
            return root;
        } else {
            const root = try getBlockRootAtSlotFn(self.state, slot);
            try self.block_root_slot_cache.put(slot, root);
            return root;
        }
    }

    pub fn deinit(self: *RootCache) void {
        self.block_root_epoch_cache.deinit();
        self.block_root_slot_cache.deinit();
        self.allocator.destroy(self);
    }
};

// TODO: unit tests
