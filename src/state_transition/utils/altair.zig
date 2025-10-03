const preset = @import("preset").preset;
const EFFECTIVE_BALANCE_INCREMENT = preset.EFFECTIVE_BALANCE_INCREMENT;
const BASE_REWARD_FACTOR = preset.BASE_REWARD_FACTOR;

pub fn computeBaseRewardPerIncrement(total_active_stake_by_increment: u64) u64 {
    const total_active_stake: f64 = @floatFromInt(total_active_stake_by_increment * EFFECTIVE_BALANCE_INCREMENT);
    const total_active_stake_sqrt_f64: f64 = @sqrt(total_active_stake);
    const total_active_stake_sqrt_u64: u64 = @intFromFloat(total_active_stake_sqrt_f64);
    return @divFloor(EFFECTIVE_BALANCE_INCREMENT * BASE_REWARD_FACTOR, total_active_stake_sqrt_u64);
}
