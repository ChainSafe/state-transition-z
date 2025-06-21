const ssz = @import("consensus_types");
const Validators = ssz.phase0.Validators.Type;
const Epoch = ssz.primitive.Epoch.Type;
const preset = ssz.preset;
const params = @import("../params.zig");
const isActiveValidator = @import("./validator.zig").isActiveValidator;

const TIMELY_TARGET = 1 << params.TIMELY_TARGET_FLAG_INDEX;

pub fn sumTargetUnslashedBalanceIncrements(participations: []const u8, epoch: Epoch, validators: Validators) u64 {
    var total: u64 = 0;
    for (participations, 0..) |participation, i| {
        if ((participation & TIMELY_TARGET) == TIMELY_TARGET) {
            const validator = validators[i];
            if (isActiveValidator(validator, epoch) and !validator.slashed) {
                total += @divFloor(validator.effective_balance / preset.EFFECTIVE_BALANCE_INCREMENT);
            }
        }
    }

    return total;
}
