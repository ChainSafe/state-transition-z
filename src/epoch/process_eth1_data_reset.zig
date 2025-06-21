const ssz = @import("consensus_types");
const phase0 = ssz.phase0;
const BeaconState = phase0.BeaconState;

pub fn processEth1DataReset(state: *BeaconState.Type) void {
    state.eth1_data_votes = ssz.phase0.Eth1DataVotes.default_value;
}
