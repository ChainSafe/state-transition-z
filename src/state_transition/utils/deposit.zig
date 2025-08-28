const params = @import("params");
const ssz = @import("consensus_types");
const preset = ssz.preset;
const Eth1Data = ssz.phase0.Eth1Data.Type;
const MAX_DEPOSITS = preset.MAX_DEPOSITS;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;

pub fn getEth1DepositCount(cached_state: *const CachedBeaconStateAllForks, eth1_data: ?*const Eth1Data) u64 {
    const state = cached_state.state;

    const eth1_data_to_use = eth1_data orelse state.eth1Data();

    if (state.isPostElectra()) {
        // eth1DataIndexLimit = min(UintNum64, UintBn64) can be safely casted as UintNum64
        // since the result lies within upper and lower bound of UintNum64
        const eth1_data_index_limit: u64 = if (eth1_data_to_use.deposit_count < state.getDepositRequestsStartIndex())
            eth1_data_to_use.deposit_count
        else
            state.getDepositRequestsStartIndex();

        return if (state.eth1DepositIndex() < eth1_data_index_limit)
            @min(MAX_DEPOSITS, eth1_data_index_limit - state.eth1DepositIndex())
        else
            0;
    }

    return @min(MAX_DEPOSITS, eth1_data_to_use.deposit_count - state.eth1DepositIndex());
}
