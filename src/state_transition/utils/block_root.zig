const ssz = @import("consensus_types");
const preset = ssz.preset;
const Root = ssz.primitive.Root.Type;
const Slot = ssz.primitive.Slot.Type;
const Epoch = ssz.primitive.Epoch.Type;
const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const params = @import("params");
const SLOTS_PER_HISTORICAL_ROOT = preset.SLOTS_PER_HISTORICAL_ROOT;
const computeStartSlotAtEpoch = @import("./epoch.zig").computeStartSlotAtEpoch;

pub fn getBlockRootAtSlot(state: *const BeaconStateAllForks, slot: Slot) !Root {
    const state_slot = state.slot();
    if (slot >= state_slot) {
        return error.SlotTooBig;
    }

    if (slot < state_slot - SLOTS_PER_HISTORICAL_ROOT) {
        return error.SlotTooSmall;
    }

    return state.blockRoots()[slot % SLOTS_PER_HISTORICAL_ROOT];
}

pub fn getBlockRoot(state: *const BeaconStateAllForks, epoch: Epoch) !Root {
    return getBlockRootAtSlot(state, computeStartSlotAtEpoch(epoch));
}

// TODO: getTemporaryBlockHeader

// TODO: signedBlockToSignedHeader
