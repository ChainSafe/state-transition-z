const types = @import("../type.zig");
const Root = types.Root;
const Slot = types.Slot;
const Epoch = types.Epoch;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const params = @import("params");
const preset = @import("consensus_types").preset;
const SLOTS_PER_HISTORICAL_ROOT = preset.SLOTS_PER_HISTORICAL_ROOT;
const computeStartSlotAtEpoch = @import("./epoch.zig").computeStartSlotAtEpoch;

pub fn getBlockRootAtSlot(state: *const BeaconStateAllForks, slot: Slot) !Root {
    const state_slot = state.getSlot();
    if (slot >= state_slot) {
        return error.SlotTooBig;
    }

    if (slot < state_slot - SLOTS_PER_HISTORICAL_ROOT) {
        return error.SlotTooSmall;
    }

    return state.getBlockRoot(slot % SLOTS_PER_HISTORICAL_ROOT);
}

pub fn getBlockRoot(state: *const BeaconStateAllForks, epoch: Epoch) !Root {
    return getBlockRootAtSlot(state, computeStartSlotAtEpoch(epoch));
}

// TODO: getTemporaryBlockHeader

// TODO: blockToHeader

// TODO: signedBlockToSignedHeader
