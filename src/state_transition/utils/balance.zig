const BeaconStateAllForks = @import("../types/beacon_state.zig").BeaconStateAllForks;
const ValidatorIndex = @import("../type.zig").ValidatorIndex;

/// Increase the balance for a validator with the given ``index`` by ``delta``.
pub fn increaseBalance(state: *BeaconStateAllForks, index: ValidatorIndex, delta: u64) void {
    state.setBalance(index, state.getBalance(index) + delta);
}

/// Decrease the balance for a validator with the given ``index`` by ``delta``.
/// Set to 0 when underflow.
pub fn decreaseBalance(state: *BeaconStateAllForks, index: ValidatorIndex, delta: u64) void {
    const current_balance = state.getBalance(index);
    const new_balance = if (current_balance > delta) current_balance - delta else 0;
    state.setBalance(index, @max(0, new_balance));
}
