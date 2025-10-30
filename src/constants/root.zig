const std = @import("std");
pub const FAR_FUTURE_EPOCH = std.math.maxInt(u64);
pub const BASE_REWARDS_PER_EPOCH = 4;
pub const DEPOSIT_CONTRACT_TREE_DEPTH = std.math.pow(usize, 2, 5); // 32
pub const JUSTIFICATION_BITS_LENGTH = 4;
pub const ZERO_HASH = [_]u8{0} ** 32;
pub const ZERO_HASH_HEX = "0x0000000000000000000000000000000000000000000000000000000000000000";
pub const GENESIS_SLOT = 0;

// Withdrawal prefixes
// Since the prefixes are just 1 byte, we define and use them as number
pub const BLS_WITHDRAWAL_PREFIX = 0;
pub const ETH1_ADDRESS_WITHDRAWAL_PREFIX = 1;
pub const COMPOUNDING_WITHDRAWAL_PREFIX = 2;

// Domain types

pub const DOMAIN_BEACON_PROPOSER = [_]u8{ 0, 0, 0, 0 };
pub const DOMAIN_BEACON_ATTESTER = [_]u8{ 1, 0, 0, 0 };
pub const DOMAIN_RANDAO = [_]u8{ 2, 0, 0, 0 };
pub const DOMAIN_DEPOSIT = [_]u8{ 3, 0, 0, 0 };
pub const DOMAIN_VOLUNTARY_EXIT = [_]u8{ 4, 0, 0, 0 };
pub const DOMAIN_SELECTION_PROOF = [_]u8{ 5, 0, 0, 0 };
pub const DOMAIN_AGGREGATE_AND_PROOF = [_]u8{ 6, 0, 0, 0 };
pub const DOMAIN_SYNC_COMMITTEE = [_]u8{ 7, 0, 0, 0 };
pub const DOMAIN_SYNC_COMMITTEE_SELECTION_PROOF = [_]u8{ 8, 0, 0, 0 };
pub const DOMAIN_CONTRIBUTION_AND_PROOF = [_]u8{ 9, 0, 0, 0 };
pub const DOMAIN_BLS_TO_EXECUTION_CHANGE = [_]u8{ 10, 0, 0, 0 };

// Application specific domains

pub const DOMAIN_APPLICATION_MASK = [_]u8{ 0, 0, 0, 1 };
pub const DOMAIN_APPLICATION_BUILDER = [_]u8{ 0, 0, 0, 1 };

// need to be updated when new domain is added
pub const ALL_DOMAINS = .{ DOMAIN_BEACON_PROPOSER, DOMAIN_BEACON_ATTESTER, DOMAIN_RANDAO, DOMAIN_DEPOSIT, DOMAIN_VOLUNTARY_EXIT, DOMAIN_SELECTION_PROOF, DOMAIN_AGGREGATE_AND_PROOF, DOMAIN_SYNC_COMMITTEE, DOMAIN_SYNC_COMMITTEE_SELECTION_PROOF, DOMAIN_CONTRIBUTION_AND_PROOF, DOMAIN_BLS_TO_EXECUTION_CHANGE, DOMAIN_APPLICATION_MASK, DOMAIN_APPLICATION_BUILDER };

// Participation flag indices

pub const TIMELY_SOURCE_FLAG_INDEX = 0;
pub const TIMELY_TARGET_FLAG_INDEX = 1;
pub const TIMELY_HEAD_FLAG_INDEX = 2;

// Incentivization weights

pub const TIMELY_SOURCE_WEIGHT = 14;
pub const TIMELY_TARGET_WEIGHT = 26;
pub const TIMELY_HEAD_WEIGHT = 14;
pub const SYNC_REWARD_WEIGHT = 2;
pub const PROPOSER_WEIGHT = 8;
pub const WEIGHT_DENOMINATOR = 64;

// altair misc

pub const PARTICIPATION_FLAG_WEIGHTS = [_]u8{ TIMELY_SOURCE_WEIGHT, TIMELY_TARGET_WEIGHT, TIMELY_HEAD_WEIGHT };

// phase0 validator

pub const TARGET_AGGREGATORS_PER_COMMITTEE = 16;
pub const RANDOM_SUBNETS_PER_VALIDATOR = 1;
pub const EPOCHS_PER_RANDOM_SUBNET_SUBSCRIPTION = 256;
/// Rationale: https://github.com/ethereum/consensus-specs/blob/v1.1.10/specs/phase0/p2p-interface.md#why-are-there-attestation_subnet_count-attestation-subnets
pub const ATTESTATION_SUBNET_COUNT = 64;
pub const SUBNETS_PER_NODE = 2;
pub const NODE_ID_BITS = 256;
pub const ATTESTATION_SUBNET_PREFIX_BITS = std.math.log2_int(usize, ATTESTATION_SUBNET_COUNT);
pub const EPOCHS_PER_SUBNET_SUBSCRIPTION = 256;

// altair validator

pub const TARGET_AGGREGATORS_PER_SYNC_SUBCOMMITTEE = 16;
pub const SYNC_COMMITTEE_SUBNET_COUNT = 4;

pub const MAX_REQUEST_BLOCKS = std.math.pow(usize, 2, 10);
pub const MAX_REQUEST_BLOCKS_DENEB = std.math.pow(usize, 2, 7);

// Lightclient pre-computed
pub const FINALIZED_ROOT_GINDEX = 105;
pub const FINALIZED_ROOT_DEPTH = 6;
pub const FINALIZED_ROOT_INDEX = 41;

pub const BLOCK_BODY_EXECUTION_PAYLOAD_GINDEX = 25;
pub const BLOCK_BODY_EXECUTION_PAYLOAD_DEPTH = 4;
pub const BLOCK_BODY_EXECUTION_PAYLOAD_INDEX = 9;

pub const NEXT_SYNC_COMMITTEE_GINDEX = 55;
pub const NEXT_SYNC_COMMITTEE_DEPTH = 5;
pub const NEXT_SYNC_COMMITTEE_INDEX = 23;
pub const MAX_REQUEST_LIGHT_CLIENT_UPDATES = 128;
pub const MAX_REQUEST_LIGHT_CLIENT_COMMITTEE_HASHES = 128;

pub const SAFE_SLOTS_TO_IMPORT_OPTIMISTICALLY = 128;
pub const INTERVALS_PER_SLOT = 3;

// EIP-4844: Crypto const
pub const BYTES_PER_FIELD_ELEMENT = 32;
pub const BLOB_TX_TYPE = 0x03;
pub const VERSIONED_HASH_VERSION_KZG = 0x01;

// Electra Misc
pub const UNSET_DEPOSIT_REQUESTS_START_INDEX = std.math.maxInt(u64);
pub const FULL_EXIT_REQUEST_AMOUNT = 0;
pub const FINALIZED_ROOT_GINDEX_ELECTRA = 169;
pub const FINALIZED_ROOT_DEPTH_ELECTRA = 7;
pub const FINALIZED_ROOT_INDEX_ELECTRA = 41;
pub const NEXT_SYNC_COMMITTEE_GINDEX_ELECTRA = 87;
pub const NEXT_SYNC_COMMITTEE_DEPTH_ELECTRA = 6;
pub const NEXT_SYNC_COMMITTEE_INDEX_ELECTRA = 23;
pub const DEPOSIT_REQUEST_TYPE = 0x00;
pub const WITHDRAWAL_REQUEST_TYPE = 0x01;
pub const CONSOLIDATION_REQUEST_TYPE = 0x02;
pub const PENDING_PARTIAL_WITHDRAWALS_LIMIT = 134_217_728;

pub const CURRENT_SYNC_COMMITTEE_GINDEX = 54;
pub const EXECUTION_PAYLOAD_GINDEX = 25;
pub const CURRENT_SYNC_COMMITTEE_GINDEX_ELECTRA = 86;

pub const G2_POINT_AT_INFINITY: [96]u8 = [_]u8{0xc0} ++ [_]u8{0} ** 95;
