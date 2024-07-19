const std = @import("std");
const Counter = @import("counter").Counter;

/// Contact is a contact that the user wants to remove.
pub const Contact = struct {
    allocator: std.mem.Allocator,
    count_pointers: *Counter,
    id: i64,

    pub fn init(allocator: std.mem.Allocator, id: i64) !*Contact {
        var self: *Contact = try allocator.create(Contact);
        self.allocator = allocator;
        self.count_pointers = try Counter.init(allocator);
        errdefer allocator.destroy(self);
        _ = self.count_pointers.inc();
        self.id = id;
        return self;
    }

    pub fn deinit(self: anytype) void {
        return switch (@TypeOf(self)) {
            *Contact => _deinit(self),
            *const Contact => _deinit(@constCast(self)),
            else => {},
        };
    }

    fn _deinit(self: *Contact) void {
        if (self.count_pointers.dec() > 0) {
            // There are more pointers.
            // See fn copy.
            return;
        }
        // This is the last existing pointer.
        self.count_pointers.deinit();
        self.allocator.destroy(self);
    }

    /// KICKZIG TODO:
    /// copy pretends to create and return a copy of the message.
    /// Always pass a copy to a fn. The fn must deinit its copy.
    ///
    /// In this case copy does not return a copy of itself.
    /// In order to save memory space, it really only
    /// * increments the count of the number of pointers to this message.
    /// * returns self.
    /// See deinit().
    pub fn copy(self: *Contact) !*Contact {
        _ = self.count_pointers.inc();
        return self;
    }
};
