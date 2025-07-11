const std = @import("std");
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;
const params = @import("params");
const ssz = @import("consensus_types");
const preset = ssz.preset;
const BeaconBlockBody = @import("../types/beacon_block.zig").BeaconBlockBody;

const getEth1DepositCount = @import("../utils/deposit.zig").getEth1DepositCount;
const processAttestations = @import("./process_attestations.zig").processAttestations;
const processAttesterSlashing = @import("./process_attester_slashing.zig").processAttesterSlashing;
const processBlsToExecutionChange = @import("./process_bls_to_execution_change.zig").processBlsToExecutionChange;
const processConsolidationRequest = @import("./process_consolidation_request.zig").processConsolidationRequest;
const processDeposit = @import("./process_deposit.zig").processDeposit;
const processDepositRequest = @import("./process_deposit_request.zig").processDepositRequest;
const processProposerSlashing = @import("./process_proposer_slashing.zig").processProposerSlashing;
const processVoluntaryExit = @import("./process_voluntary_exit.zig").processVoluntaryExit;
const processWithdrawalRequest = @import("./process_withdrawal_request.zig").processWithdrawalRequest;
const ProcessBlockOpts = @import("./types.zig").ProcessBlockOpts;

pub fn processOperations(cached_state: *CachedBeaconStateAllForks, body: *const BeaconBlockBody, opts: ?ProcessBlockOpts) !void {
    const state = cached_state.state;

    // verify that outstanding deposits are processed up to the maximum number of deposits
    const max_deposits = getEth1DepositCount(cached_state, null);
    if (body.getDeposits().len != max_deposits) {
        return error.InvalidDepositCount;
    }

    const verify_signatures: ?bool = if (opts) |o| o.verify_signature else null;

    for (body.getProposerSlashings()) |*proposer_slashing| {
        try processProposerSlashing(cached_state, proposer_slashing, verify_signatures);
    }

    const attester_slashings = body.getAttesterSlashings().items();
    switch (attester_slashings) {
        .phase0 => |attester_slashings_phase0| {
            for (attester_slashings_phase0) |*attester_slashing| {
                try processAttesterSlashing(ssz.phase0.AttesterSlashing.Type, cached_state, attester_slashing, verify_signatures);
            }
        },
        .electra => |attester_slashings_electra| {
            for (attester_slashings_electra) |*attester_slashing| {
                try processAttesterSlashing(ssz.electra.AttesterSlashing.Type, cached_state, attester_slashing, verify_signatures);
            }
        },
    }

    try processAttestations(cached_state, body.getAttestations(), verify_signatures);

    for (body.getDeposits()) |*deposit| {
        try processDeposit(cached_state, deposit);
    }

    for (body.getVoluntaryExits()) |*voluntary_exit| {
        try processVoluntaryExit(cached_state, voluntary_exit, verify_signatures);
    }

    if (state.isPostCapella()) {
        for (body.getBlsToExecutionChanges()) |*bls_to_execution_change| {
            try processBlsToExecutionChange(cached_state, bls_to_execution_change);
        }
    }

    if (state.isPostElectra()) {
        for (body.getDepositRequests()) |*deposit_request| {
            try processDepositRequest(cached_state, deposit_request);
        }

        for (body.getWithdrawalRequests()) |*withdrawal_request| {
            try processWithdrawalRequest(cached_state, withdrawal_request);
        }

        for (body.getConsolidationRequests()) |*consolidation_request| {
            try processConsolidationRequest(cached_state, consolidation_request);
        }
    }
}
