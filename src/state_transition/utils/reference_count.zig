const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn getReferenceCount(comptime T: type) type {
    return struct {
        // TODO: switch to std.atomic
        _ref_count: usize,
        instance: *T,

        pub fn init(instance: *T) *@This() {
            return .{
                .ref_count = 1,
                .instance = instance,
            };
        }

        pub fn clone(allocator: Allocator, instance: *T) !*@This() {
            const cloned = try instance.clone(allocator);
            return @This().init(cloned);
        }

        pub fn get(self: *@This()) *T {
            return self.instance;
        }

        pub fn getConst(self: *@This()) *const T {
            return self.instance;
        }

        pub fn acquire(self: *@This()) *@This() {
            self._ref_count += 1;
            return self;
        }

        pub fn release(self: *@This()) void {
            self._ref_count -= 1;
            if (self._ref_count == 0) {
                self.instance.deinit();
            }
        }
    };
}
