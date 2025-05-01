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

// this special index 4,294,967,295 is used to mark a not found
pub const NOT_FOUND_INDEX = 0xffffffff;
pub const ERROR_INDEX = 0xffffffff;
