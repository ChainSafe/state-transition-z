pub const ExecutionPayloadStatus = enum(u8) {
    pre_merge,
    invalid,
    valid,
};

pub const DataAvailabilityStatus = enum(u8) {
    pre_data,
    out_of_range,
    available,
};

pub const BlockExternalData = struct {
    execution_payload_status: ExecutionPayloadStatus,
    data_availability_status: DataAvailabilityStatus,
};
