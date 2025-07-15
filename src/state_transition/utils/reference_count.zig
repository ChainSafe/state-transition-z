const std = @import("std");
const Allocator = std.mem.Allocator;

/// A reference counted wrapper for a type `T`.
/// T should be `*Something`, not `*const Something` due to deinit()
pub fn getReferenceCount(comptime T: type) type {
    return struct {
        // TODO: switch to std.atomic
        allocator: Allocator,
        _ref_count: usize,
        instance: T,

        pub fn init(allocator: Allocator, instance: T) !*@This() {
            const ptr = try allocator.create(@This());
            ptr.* = .{
                .allocator = allocator,
                ._ref_count = 1,
                .instance = instance,
            };
            return ptr;
        }

        pub fn deinit(self: *@This()) void {
            self.instance.deinit();
            self.allocator.destroy(self);
        }

        pub fn clone(allocator: Allocator, instance: T) !*@This() {
            const cloned = try instance.clone(allocator);
            return @This().init(cloned);
        }

        pub fn get(self: *@This()) T {
            return self.instance;
        }

        pub fn acquire(self: *@This()) *@This() {
            self._ref_count += 1;
            return self;
        }

        pub fn release(self: *@This()) void {
            self._ref_count -= 1;
            if (self._ref_count == 0) {
                self.deinit();
            }
        }
    };
}

// TODO: unit tests
