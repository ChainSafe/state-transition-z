test "process blob kzg commitments - sanity" {
    try processBlobKzgCommitments(.{
        .execution_payload_status = .valid,
        .data_availability_status = .available,
    });
}

const processBlobKzgCommitments = @import("state_transition").processBlobKzgCommitments;
