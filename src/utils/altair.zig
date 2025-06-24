const params = @import("../params.zig");
const EFFECTIVE_BALANCE_INCREMENT = params.EFFECTIVE_BALANCE_INCREMENT;
const BASE_REWARD_FACTOR = params.BASE_REWARD_FACTOR;

pub fn computeBaseRewardPerIncrement(total_active_stake_by_increment: u64) u64 {
    return @divFloor(EFFECTIVE_BALANCE_INCREMENT * BASE_REWARD_FACTOR, @sqrt(total_active_stake_by_increment * EFFECTIVE_BALANCE_INCREMENT));
}
