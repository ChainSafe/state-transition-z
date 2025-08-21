const BlockExternalData = @import("./external_data.zig").BlockExternalData;
const CachedBeaconStateAllForks = @import("../cache/state_cache.zig").CachedBeaconStateAllForks;

pub fn processBlobKzgCommitments(external_data: BlockExternalData) !void {
    switch (external_data.execution_payload_status) {
        .pre_merge => return error.ExecutionPayloadStatusPreMerge,
        .invalid => return error.InvalidExecutionPayload,
        // ok
        else => {},
    }
}
