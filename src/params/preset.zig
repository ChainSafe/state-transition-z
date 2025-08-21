const Preset_Mainnet = "mainnet";
const Preset_Minimal = "minimal";
const Preset_Gnosis = "gnosis";

pub const Preset = enum(u8) {
    mainnet = 0,
    minimal = 1,
    gnosis = 2,

    pub fn getPresetName(self: Preset) []const u8 {
        return switch (self) {
            .mainnet => Preset_Mainnet,
            .minimal => Preset_Minimal,
            .gnosis => Preset_Gnosis,
        };
    }
};
