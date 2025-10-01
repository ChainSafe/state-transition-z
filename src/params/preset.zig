pub const Preset = enum(u8) {
    mainnet = 0,
    minimal = 1,
    gnosis = 2,

    pub fn getPresetName(self: Preset) []const u8 {
        @tagName(self);
    }
};
