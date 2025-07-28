const std = @import("std");
const testing = std.testing;
const epoch_transition_cache = @import("./cache/epoch_transition_cache.zig");
const process_justification_and_finalization = @import("./epoch/process_justification_and_finalization.zig");
const process_inactivity_updates = @import("./epoch/process_inactivity_updates.zig");
const process_registry_updates = @import("./epoch/process_registry_updates.zig");
const process_slashings = @import("./epoch/process_slashings.zig");
const process_rewards_and_penalties = @import("./epoch/process_rewards_and_penalties.zig");
const process_eth1_data_reset = @import("./epoch/process_eth1_data_reset.zig");
const process_pending_deposits = @import("./epoch/process_pending_deposits.zig");
const process_pending_consolidations = @import("./epoch/process_pending_consolidations.zig");
const process_effective_balance_updates = @import("./epoch/process_effective_balance_updates.zig");
const process_slashings_reset = @import("./epoch/process_slashings_reset.zig");

test {
    testing.refAllDecls(epoch_transition_cache);
    testing.refAllDecls(process_justification_and_finalization);
    testing.refAllDecls(process_rewards_and_penalties);
    testing.refAllDecls(process_inactivity_updates);
    testing.refAllDecls(process_slashings);
    testing.refAllDecls(process_registry_updates);
    testing.refAllDecls(process_eth1_data_reset);
    testing.refAllDecls(process_pending_deposits);
    testing.refAllDecls(process_pending_consolidations);
    testing.refAllDecls(process_effective_balance_updates);
    testing.refAllDecls(process_slashings_reset);
}
