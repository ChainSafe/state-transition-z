const std = @import("std");
const Allocator = std.mem.Allocator;
const ssz = @import("consensus_types");
const preset = ssz.preset;
const ForkData = ssz.phase0.ForkData.Type;
const Epoch = ssz.primitive.Epoch.Type;
const Slot = ssz.primitive.Slot.Type;
const Version = ssz.primitive.Version.Type;
const Root = ssz.primitive.Root.Type;
const DomainType = ssz.primitive.DomainType.Type;
const DOMAIN_VOLUNTARY_EXIT = @import("./params.zig").DOMAIN_VOLUNTARY_EXIT;

/// Run-time chain configuration
/// This starts with ChainConfig, similar to typescript version
const ChainConfig = struct {
    // TODO: should this be enum
    PRESET_BASE: []const u8,
    CONFIG_NAME: []const u8, // string in TS

    // Transition
    TERMINAL_TOTAL_DIFFICULTY: u256,
    TERMINAL_BLOCK_HASH: [32]u8,
    TERMINAL_BLOCK_HASH_ACTIVATION_EPOCH: u64,

    // Genesis
    MIN_GENESIS_ACTIVE_VALIDATOR_COUNT: u64,
    MIN_GENESIS_TIME: u64,
    GENESIS_FORK_VERSION: [4]u8,
    GENESIS_DELAY: u64,

    // Altair
    ALTAIR_FORK_VERSION: [4]u8,
    ALTAIR_FORK_EPOCH: u64,
    // Bellatrix
    BELLATRIX_FORK_VERSION: [4]u8,
    BELLATRIX_FORK_EPOCH: u64,
    // Capella
    CAPELLA_FORK_VERSION: [4]u8,
    CAPELLA_FORK_EPOCH: u64,
    // DENEB
    DENEB_FORK_VERSION: [4]u8,
    DENEB_FORK_EPOCH: u64,
    // ELECTRA
    ELECTRA_FORK_VERSION: [4]u8,
    ELECTRA_FORK_EPOCH: u64,
    // FULU (assuming it's a future fork, standard pattern)
    FULU_FORK_VERSION: [4]u8,
    FULU_FORK_EPOCH: u64,

    // Time parameters
    SECONDS_PER_SLOT: u64,
    SECONDS_PER_ETH1_BLOCK: u64,
    MIN_VALIDATOR_WITHDRAWABILITY_DELAY: u64,
    SHARD_COMMITTEE_PERIOD: u64,
    ETH1_FOLLOW_DISTANCE: u64,

    // Validator cycle
    INACTIVITY_SCORE_BIAS: u64,
    INACTIVITY_SCORE_RECOVERY_RATE: u64,
    EJECTION_BALANCE: u64,
    MIN_PER_EPOCH_CHURN_LIMIT: u64,
    MAX_PER_EPOCH_ACTIVATION_CHURN_LIMIT: u64,
    CHURN_LIMIT_QUOTIENT: u64,
    MAX_PER_EPOCH_ACTIVATION_EXIT_CHURN_LIMIT: u64,
    MIN_PER_EPOCH_CHURN_LIMIT_ELECTRA: u64,

    // Fork choice
    PROPOSER_SCORE_BOOST: u64,
    REORG_HEAD_WEIGHT_THRESHOLD: u64,
    REORG_PARENT_WEIGHT_THRESHOLD: u64,
    REORG_MAX_EPOCHS_SINCE_FINALIZATION: u64,

    // Deposit contract
    DEPOSIT_CHAIN_ID: u64,
    DEPOSIT_NETWORK_ID: u64,
    DEPOSIT_CONTRACT_ADDRESS: [20]u8,

    // Networking
    MIN_EPOCHS_FOR_BLOCK_REQUESTS: u64,
    MIN_EPOCHS_FOR_BLOB_SIDECARS_REQUESTS: u64,
    MIN_EPOCHS_FOR_DATA_COLUMN_SIDECARS_REQUESTS: u64,
    BLOB_SIDECAR_SUBNET_COUNT: u64,
    MAX_BLOBS_PER_BLOCK: u64,
    MAX_REQUEST_BLOB_SIDECARS: u64,
    BLOB_SIDECAR_SUBNET_COUNT_ELECTRA: u64,
    MAX_BLOBS_PER_BLOCK_ELECTRA: u64,
    MAX_REQUEST_BLOB_SIDECARS_ELECTRA: u64,

    SAMPLES_PER_SLOT: u64,
    CUSTODY_REQUIREMENT: u64,
    NODE_CUSTODY_REQUIREMENT: u64,
    VALIDATOR_CUSTODY_REQUIREMENT: u64,
    BALANCE_PER_ADDITIONAL_CUSTODY_GROUP: u64,

    // Blob Scheduling
    BLOB_SCHEDULE: []BlobScheduleEntry,
};

const BlobScheduleEntry = struct {
    EPOCH: Epoch,
    MAX_BLOBS_PER_BLOCK: u64,
};

const DomainByTypeHashMap = std.AutoHashMap([]const u8, []const u8);
const DomainByTypeByForkHashMap = std.AutoHashMap([]const u8, DomainByTypeHashMap);
const ForkInfoHashMap = std.AutoHashMap([]const u8, ForkInfo);

const BeaconConfig = struct {
    allocator: Allocator,
    config: ChainConfig,
    forks: ForkInfoHashMap,
    forks_ascending_epoch_order: [6]ForkInfo,
    forks_descending_epoch_order: [6]ForkInfo,
    genesis_validator_root: Root,
    domain_cache: DomainByTypeByForkHashMap,

    pub fn init(allocator: Allocator, config: ChainConfig, genesis_validator_root: Root) !*BeaconConfig {
        const phase0 = ForkInfo{
            .name = "phase0",
            .seq = ForkSeq.phase0,
            .epoch = 0,
            .version = config.GENESIS_FORK_VERSION,
            .prevVersion = [4]u8{ 0, 0, 0, 0 },
            .prevForkName = "phase0",
        };

        const altair = ForkInfo{
            .name = "altair",
            .seq = ForkSeq.altair,
            .epoch = config.ALTAIR_FORK_EPOCH,
            .version = config.ALTAIR_FORK_VERSION,
            .prevVersion = config.GENESIS_FORK_VERSION,
            .prevForkName = phase0.name,
        };

        const bellatrix = ForkInfo{
            .name = "bellatrix",
            .seq = ForkSeq.bellatrix,
            .epoch = config.BELLATRIX_FORK_EPOCH,
            .version = config.BELLATRIX_FORK_VERSION,
            .prevVersion = config.ALTAIR_FORK_VERSION,
            .prevForkName = altair.name,
        };

        const capella = ForkInfo{
            .name = "capella",
            .seq = ForkSeq.capella,
            .epoch = config.CAPELLA_FORK_EPOCH,
            .version = config.CAPELLA_FORK_VERSION,
            .prevVersion = config.BELLATRIX_FORK_VERSION,
            .prevForkName = bellatrix.name,
        };

        const deneb = ForkInfo{
            .name = "deneb",
            .seq = ForkSeq.deneb,
            .epoch = config.DENEB_FORK_EPOCH,
            .version = config.DENEB_FORK_VERSION,
            .prevVersion = config.CAPELLA_FORK_VERSION,
            .prevForkName = capella.name,
        };

        const electra = ForkInfo{
            .name = "electra",
            .seq = ForkSeq.electra,
            .epoch = config.ELECTRA_FORK_EPOCH,
            .version = config.ELECTRA_FORK_VERSION,
            .prevVersion = config.DENEB_FORK_VERSION,
            .prevForkName = deneb.name,
        };

        const forks_ascending_epoch_order = [_]ForkInfo{
            phase0,
            altair,
            bellatrix,
            capella,
            deneb,
            electra,
        };
        const forks = ForkInfoHashMap.init(allocator);
        try forks.put(phase0.name, phase0);
        try forks.put(altair.name, altair);
        try forks.put(bellatrix.name, bellatrix);
        try forks.put(capella.name, capella);
        try forks.put(deneb.name, deneb);
        try forks.put(electra.name, electra);

        const domain_cache = DomainByTypeByForkHashMap.init(allocator);

        const beacon_config = try allocator.create(BeaconConfig);
        beacon_config.* = BeaconConfig{
            .allocator = allocator,
            .config = config,
            .forks = forks,
            .forks_ascending_epoch_order = forks_ascending_epoch_order,
            .forks_descending_epoch_order = [_]ForkInfo{
                electra,
                deneb,
                capella,
                bellatrix,
                altair,
                phase0,
            },
            .genesis_validator_root = genesis_validator_root,
            .domain_cache = domain_cache,
        };

        return beacon_config;
    }

    pub fn deinit(self: *BeaconConfig) void {
        self.forks.deinit();
        for (self.domain_cache.iterator()) |entry| {
            // TODO: fix this
            entry.value.deinit();
        }
        self.domain_cache.deinit();
        self.allocator.destroy(self);
    }

    pub fn getForkInfo(self: *const BeaconConfig, slot: Slot) ForkInfo {
        const epoch = @divFloor(slot, preset.SLOTS_PER_EPOCH);
        return self.getForkInfoAtEpoch(epoch);
    }

    pub fn getForkInfoAtEpoch(self: *const BeaconConfig, epoch: Epoch) ForkInfo {
        // NOTE: forks must be sorted by descending epoch, latest fork first
        for (self.forks_descending_epoch_order) |fork| {
            if (epoch >= fork.epoch) {
                return fork;
            }
        }

        // phase0
        return self.forks[0];
    }

    pub fn getForkName(self: *const BeaconConfig, slot: Slot) []const u8 {
        return self.getForkInfo(slot).name;
    }

    pub fn getForkSeq(self: *const BeaconConfig, slot: Slot) ForkSeq {
        return self.getForkInfo(slot).seq;
    }

    pub fn getForkSeqAtEpoch(self: *const BeaconConfig, epoch: Epoch) ForkSeq {
        return self.getForkInfoAtEpoch(epoch).seq;
    }

    pub fn getForkVersion(self: *const BeaconConfig, slot: Slot) [4]u8 {
        return self.getForkInfo(slot).version;
    }

    // TODO: is getForkTypes() necessary?
    // TODO: getPostBellatrixForkTypes
    // TODO: getPostAltairForkTypes
    // TODO: getPostDenebForkTypes
    // TODO: getMaxBlobsPerBlock
    // TODO: getMaxRequestBlobSidecars

    pub fn getDomain(self: *BeaconConfig, state_slot: Slot, domain_type: DomainType, message_slot: ?Slot) ![32]u8 {
        const slot = if (message_slot) |s| s else state_slot;
        const epoch = @divFloor(slot, preset.SLOTS_PER_EPOCH);
        const state_fork_info = self.getForkInfo(state_slot);
        const fork_name = if (epoch < state_fork_info.epoch) state_fork_info.prevForkName else state_fork_info.name;
        const fork_info = self.forks.get(fork_name) orelse return error.ForkNameNotFound;

        const domain_by_type = self.domain_cache.get(fork_name) orelse {
            const new_map = DomainByTypeHashMap.init(self.allocator);
            self.domain_cache.put(fork_name, new_map) catch error.DomainCachePutFailed;
            return new_map;
        };

        const domain = domain_by_type.get(domain_type) orelse {
            const out = try self.allocator.create([32]u8);
            computeDomain(domain_type, fork_info.version, self.genesis_validator_root, out);
            try domain_by_type.put(domain_type, out);
            return out;
        };

        return domain.*;
    }

    pub fn getDomainAtFork(self: *BeaconConfig, fork_name: []const u8, domain_type: DomainType) ![32]u8 {
        const fork_info = self.forks.get(fork_name) orelse return error.ForkNameNotFound;
        const domain_by_type = self.domain_cache.get(fork_name) orelse {
            const new_map = DomainByTypeHashMap.init(self.allocator);
            self.domain_cache.put(fork_name, new_map) catch return error.DomainCachePutFailed;
            return new_map;
        };

        const domain = domain_by_type.get(domain_type) orelse {
            const out = try self.allocator.create([32]u8);
            computeDomain(domain_type, fork_info.version, self.genesis_validator_root, out);
            try domain_by_type.put(domain_type, out);
            return out;
        };

        return domain.*;
    }

    pub fn getDomainForVoluntaryExit(self: *BeaconConfig, state_slot: Slot, message_slot: ?Slot) ![32]u8 {
        const domain = if (state_slot < self.config.DENEB_FORK_EPOCH * preset.SLOTS_PER_EPOCH) {
            return self.getDomain(state_slot, DOMAIN_VOLUNTARY_EXIT, message_slot);
        } else {
            return self.getDomainAtFork(Fork_Name_Capella, DOMAIN_VOLUNTARY_EXIT);
        };

        return domain;
    }

    // TODO: forkDigest2ForkName, forkDigest2ForkNameOption, forkName2ForkDigest, forkName2ForkDigestHex
    // may not need it for state-transition
};

fn computeDomain(domain_type: DomainType, fork_version: Version, genesis_validators_root: Root, out: *[32]u8) void {
    computeForkDataRoot(fork_version, genesis_validators_root, out);
    std.mem.copyForwards(u8, out[0..], domain_type[0..]);
}

fn computeForkDataRoot(current_version: Version, genesis_validators_root: Root, out: *[32]u8) void {
    const fork_data: ForkData = .{
        .current_version = current_version,
        .genesis_validators_root = genesis_validators_root,
    };
    ssz.phase0.ForkData.hashTreeRoot(&fork_data, out);
}

const Fork_Name_Phase0 = "phase0";
const Fork_Name_Altair = "altair";
const Fork_Name_Bellatrix = "bellatrix";
const Fork_Name_Capella = "capella";
const Fork_Name_Deneb = "deneb";
const Fork_Name_Electra = "electra";

pub const ForkSeq = enum(u8) {
    phase0 = 0,
    altair = 1,
    bellatrix = 2,
    capella = 3,
    deneb = 4,
    electra = 5,
    fulu = 6,
};

const ForkInfo = struct {
    name: []const u8,
    seq: ForkSeq,
    epoch: Epoch,
    version: Version,
    prevVersion: Version,
    prevForkName: []const u8,
};

// TODO: unit tests
