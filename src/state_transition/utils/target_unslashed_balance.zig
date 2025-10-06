const ssz = @import("consensus_types");
const Validators = ssz.phase0.Validators.Type;
const Validator = ssz.phase0.Validator.Type;
const Epoch = ssz.primitive.Epoch.Type;
const preset = @import("preset").preset;
const c = @import("constants");
const isActiveValidator = @import("./validator.zig").isActiveValidator;

const TIMELY_TARGET = 1 << c.TIMELY_TARGET_FLAG_INDEX;

pub fn sumTargetUnslashedBalanceIncrements(participations: []const u8, epoch: Epoch, validators: []Validator) u64 {
    var total: u64 = 0;
    for (participations, 0..) |participation, i| {
        if ((participation & TIMELY_TARGET) == TIMELY_TARGET) {
            const validator = &validators[i];
            if (isActiveValidator(validator, epoch) and !validator.slashed) {
                total += @divFloor(validator.effective_balance, preset.EFFECTIVE_BALANCE_INCREMENT);
            }
        }
    }

    return total;
}
