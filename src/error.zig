pub const ErrorCode = struct {
    pub const Success: c_uint = 0;
    pub const InvalidInput: c_uint = 1;
    pub const Error: c_uint = 2;
    pub const TooManyThreadError: c_uint = 2;
    pub const MemoryError: c_uint = 3;
    pub const ThreadError: c_uint = 4;
    pub const InvalidPointerError: c_uint = 5;
    pub const Pending: c_uint = 10;
};
