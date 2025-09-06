pub const SpecTestRunner = enum(u8) {
    epoch_processing,
    finality,
    operations,
    random,
    rewards,
    sanity,
    shuffling,
};
