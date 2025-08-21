const std = @import("std");
const testing = std.testing;
pub const BeaconConfig = @import("./beacon_config.zig").BeaconConfig;
pub const ChainConfig = @import("./chain/chain_config.zig").ChainConfig;
pub const mainnet_chain_config = @import("./chain/networks/mainnet.zig").mainnet_chain_config;
pub const gnosis_chain_config = @import("./chain/networks/gnosis.zig").gnosis_chain_config;
pub const chiado_chain_config = @import("./chain/networks/chiado.zig").chiado_chain_config;
pub const sepolia_chain_config = @import("./chain/networks/sepolia.zig").sepolia_chain_config;
pub const hoodi_chain_config = @import("./chain/networks/hoodi.zig").hoodi_chain_config;

test {
    testing.refAllDecls(@This());
}
