const std = @import("std");
const ssz = @import("consensus_types");
const types = @import("../type.zig");
const Domain = types.Domain;
const Version = types.Version;
const DomainType = types.DomainType;
const Root = types.Root;
const Fork = types.Fork;
const Epoch = types.Epoch;

// Only used by processDeposit +  lightclient

/// Return the domain for the [[domainType]] and [[forkVersion]].
pub fn computeDomain(domain_type: DomainType, fork_version: Version, genesis_validator_root: Root, out: *Domain) !void {
    var fork_data_root: Root = undefined;
    try computeForkDataRoot(fork_version, genesis_validator_root, &fork_data_root);
    std.mem.copyForwards(u8, out[0..4], domain_type[0..4]);
    std.mem.copyForwards(u8, out[4..32], fork_data_root[0..28]);
}

/// Return the ForkVersion at an epoch from a Fork type
pub fn getForkVersion(fork: Fork, epoch: Epoch) Version {
    return if (epoch < fork.epoch) fork.previousVersion else fork.currentVersion;
}

/// Used primarily in signature domains to avoid collisions across forks/chains.
pub fn computeForkDataRoot(current_version: Version, genesis_validators_root: Root, out: *Root) !void {
    const fork_data: ssz.phase0.ForkData.Type = .{
        .current_version = current_version,
        .genesis_validators_root = genesis_validators_root,
    };
    try ssz.phase0.ForkData.hashTreeRoot(&fork_data, out);
}
