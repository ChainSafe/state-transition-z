const types = @import("../type.zig");
const WithdrawalCredentials = types.WithdrawalCredentials;
const params = @import("../params.zig");
const ETH1_ADDRESS_WITHDRAWAL_PREFIX = params.ETH1_ADDRESS_WITHDRAWAL_PREFIX;

/// https://github.com/ethereum/consensus-specs/blob/3d235740e5f1e641d3b160c8688f26e7dc5a1894/specs/capella/beacon-chain.md#has_eth1_withdrawal_credential
pub fn hasEth1WithdrawalCredential(withdrawal_credentials: WithdrawalCredentials) bool {
    return withdrawal_credentials[0] == ETH1_ADDRESS_WITHDRAWAL_PREFIX;
}
