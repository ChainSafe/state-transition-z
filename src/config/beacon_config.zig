const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const preset = @import("preset").preset;
const ForkData = ssz.phase0.ForkData.Type;
const Epoch = ssz.primitive.Epoch.Type;
const Slot = ssz.primitive.Slot.Type;
const Version = ssz.primitive.Version.Type;
const Root = ssz.primitive.Root.Type;
const DomainType = ssz.primitive.DomainType.Type;
const c = @import("constants");
const DOMAIN_VOLUNTARY_EXIT = c.DOMAIN_VOLUNTARY_EXIT;
const forks = @import("./fork.zig");
const ForkSeq = forks.ForkSeq;
const ForkInfo = forks.ForkInfo;
const TOTAL_FORKS = forks.TOTAL_FORKS;
const forkSeqByForkName = forks.forkSeqByForkName;

const DomainByTypeHashMap = std.StringHashMap([]const u8);
const DomainByTypeByFork = std.ArrayList(DomainByTypeHashMap);

pub const ChainConfig = @import("./chain/chain_config.zig").ChainConfig;

pub const BeaconConfig = struct {
    allocator: Allocator,
    chain: ChainConfig,
    forks_ascending_epoch_order: [TOTAL_FORKS]ForkInfo,
    forks_descending_epoch_order: [TOTAL_FORKS]ForkInfo,
    genesis_validator_root: Root,
    domain_cache: DomainByTypeByFork,

    pub fn init(allocator: Allocator, chain_config: ChainConfig, genesis_validator_root: Root) !*BeaconConfig {
        const phase0 = ForkInfo{
            .fork_seq = ForkSeq.phase0,
            .epoch = 0,
            .version = chain_config.GENESIS_FORK_VERSION,
            .prev_version = [4]u8{ 0, 0, 0, 0 },
            .prev_fork_seq = ForkSeq.phase0,
        };

        const altair = ForkInfo{
            .fork_seq = ForkSeq.altair,
            .epoch = chain_config.ALTAIR_FORK_EPOCH,
            .version = chain_config.ALTAIR_FORK_VERSION,
            .prev_version = chain_config.GENESIS_FORK_VERSION,
            .prev_fork_seq = ForkSeq.phase0,
        };

        const bellatrix = ForkInfo{
            .fork_seq = ForkSeq.bellatrix,
            .epoch = chain_config.BELLATRIX_FORK_EPOCH,
            .version = chain_config.BELLATRIX_FORK_VERSION,
            .prev_version = chain_config.ALTAIR_FORK_VERSION,
            .prev_fork_seq = ForkSeq.altair,
        };

        const capella = ForkInfo{
            .fork_seq = ForkSeq.capella,
            .epoch = chain_config.CAPELLA_FORK_EPOCH,
            .version = chain_config.CAPELLA_FORK_VERSION,
            .prev_version = chain_config.BELLATRIX_FORK_VERSION,
            .prev_fork_seq = ForkSeq.bellatrix,
        };

        const deneb = ForkInfo{
            .fork_seq = ForkSeq.deneb,
            .epoch = chain_config.DENEB_FORK_EPOCH,
            .version = chain_config.DENEB_FORK_VERSION,
            .prev_version = chain_config.CAPELLA_FORK_VERSION,
            .prev_fork_seq = ForkSeq.capella,
        };

        const electra = ForkInfo{
            .fork_seq = ForkSeq.electra,
            .epoch = chain_config.ELECTRA_FORK_EPOCH,
            .version = chain_config.ELECTRA_FORK_VERSION,
            .prev_version = chain_config.DENEB_FORK_VERSION,
            .prev_fork_seq = ForkSeq.deneb,
        };

        const forks_ascending_epoch_order = [_]ForkInfo{
            phase0,
            altair,
            bellatrix,
            capella,
            deneb,
            electra,
        };
        const forks_descending_epoch_order = [_]ForkInfo{
            electra,
            deneb,
            capella,
            bellatrix,
            altair,
            phase0,
        };

        var domain_cache = DomainByTypeByFork.init(allocator);
        for (0..TOTAL_FORKS) |_| {
            try domain_cache.append(DomainByTypeHashMap.init(allocator));
        }

        const beacon_config = try allocator.create(BeaconConfig);
        beacon_config.* = BeaconConfig{
            .allocator = allocator,
            .chain = chain_config,
            .forks_ascending_epoch_order = forks_ascending_epoch_order,
            .forks_descending_epoch_order = forks_descending_epoch_order,
            .genesis_validator_root = genesis_validator_root,
            .domain_cache = domain_cache,
        };

        return beacon_config;
    }

    pub fn deinit(self: *BeaconConfig) void {
        for (0..TOTAL_FORKS) |i| {
            self.domain_cache.items[i].deinit();
        }
        self.domain_cache.deinit();
        self.allocator.destroy(self);
    }

    pub fn forkInfo(self: *const BeaconConfig, slot: Slot) ForkInfo {
        const epoch = @divFloor(slot, preset.SLOTS_PER_EPOCH);
        return self.forkInfoAtEpoch(epoch);
    }

    pub fn forkInfoAtEpoch(self: *const BeaconConfig, epoch: Epoch) ForkInfo {
        // NOTE: forks must be sorted by descending epoch, latest fork first
        for (self.forks_descending_epoch_order) |fork| {
            if (epoch >= fork.epoch) {
                return fork;
            }
        }

        // phase0
        return self.forks_ascending_epoch_order[@intFromEnum(ForkSeq.phase0)];
    }

    pub fn forkName(self: *const BeaconConfig, slot: Slot) []const u8 {
        return self.forkInfo(slot).name;
    }

    pub fn forkSeq(self: *const BeaconConfig, slot: Slot) ForkSeq {
        return self.forkInfo(slot).fork_seq;
    }

    pub fn forkSeqAtEpoch(self: *const BeaconConfig, epoch: Epoch) ForkSeq {
        return self.forkInfoAtEpoch(epoch).fork_seq;
    }

    pub fn forkVersion(self: *const BeaconConfig, slot: Slot) [4]u8 {
        return self.forkInfo(slot).version;
    }

    // TODO: is forkTypes() necessary?
    // TODO: getPostBellatrixForkTypes
    // TODO: getPostAltairForkTypes
    // TODO: getPostDenebForkTypes
    pub fn getMaxBlobsPerBlock(self: *const BeaconConfig, epoch: Epoch) u64 {
        const fork = self.forkInfoAtEpoch(epoch).fork_seq;
        return switch (fork) {
            .deneb => self.chain.MAX_BLOBS_PER_BLOCK,
            .electra => self.chain.MAX_BLOBS_PER_BLOCK_ELECTRA,
            else =>
            // For forks before Deneb, we assume no blobs
            0,
        };
    }

    pub fn getMaxRequestBlobSidecars(self: *const BeaconConfig, fork: ForkSeq) u64 {
        return if (fork.isForkPostElectra()) self.chain.MAX_REQUEST_BLOB_SIDECARS_ELECTRA else self.chain.MAX_REQUEST_BLOB_SIDECARS;
    }

    pub fn getDomain(self: *const BeaconConfig, state_slot: Slot, domain_type: DomainType, message_slot: ?Slot) ![32]u8 {
        const slot = if (message_slot) |s| s else state_slot;
        const epoch = @divFloor(slot, preset.SLOTS_PER_EPOCH);
        const state_fork_info = self.forkInfo(state_slot);
        const fork_seq = if (epoch < state_fork_info.epoch) state_fork_info.prev_fork_seq else state_fork_info.fork_seq;

        return self.getDomainByForkSeq(fork_seq, domain_type);
    }

    // TODO: may not need this method
    pub fn getDomainByForkName(self: *const BeaconConfig, fork_name: []const u8, domain_type: DomainType) ![32]u8 {
        const fork_seq = forkSeqByForkName(fork_name);
        return try self.getDomainByForkSeq(fork_seq, domain_type);
    }

    pub fn getDomainByForkSeq(self: *const BeaconConfig, fork_seq: ForkSeq, domain_type: DomainType) ![32]u8 {
        if (@intFromEnum(fork_seq) >= TOTAL_FORKS) return error.ForkSeqOutOfRange;

        var domain_by_type = self.domain_cache.items[@intFromEnum(fork_seq)];
        var domain: [32]u8 = undefined;

        if (domain_by_type.get(&domain_type)) |d| @memcpy(&domain, d) else {
            const out = try self.allocator.create([32]u8);
            const fork_info = self.forks_ascending_epoch_order[@intFromEnum(fork_seq)];
            try computeDomain(domain_type, fork_info.version, self.genesis_validator_root, out);
            try domain_by_type.put(&domain_type, out);
            @memcpy(&domain, out);
        }

        return domain;
    }

    pub fn getDomainForVoluntaryExit(self: *const BeaconConfig, state_slot: Slot, message_slot: ?Slot) ![32]u8 {
        const domain = if (state_slot < self.chain.DENEB_FORK_EPOCH * preset.SLOTS_PER_EPOCH) {
            return self.getDomain(state_slot, DOMAIN_VOLUNTARY_EXIT, message_slot);
        } else {
            return self.getDomainByForkSeq(ForkSeq.capella, DOMAIN_VOLUNTARY_EXIT);
        };

        return domain;
    }

    // TODO: forkDigest2ForkName, forkDigest2ForkNameOption, forkName2ForkDigest, forkName2ForkDigestHex
    // may not need it for state-transition
};

fn computeDomain(domain_type: DomainType, fork_version: Version, genesis_validators_root: Root, out: *[32]u8) !void {
    try computeForkDataRoot(fork_version, genesis_validators_root, out);
    std.mem.copyForwards(u8, out[0..], domain_type[0..]);
}

fn computeForkDataRoot(current_version: Version, genesis_validators_root: Root, out: *[32]u8) !void {
    const fork_data: ForkData = .{
        .current_version = current_version,
        .genesis_validators_root = genesis_validators_root,
    };
    try ssz.phase0.ForkData.hashTreeRoot(&fork_data, out);
}

// TODO: unit tests
