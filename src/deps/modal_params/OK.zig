const std = @import("std");

/// Params is the parameters for the OK modal screen's state.
/// See src/frontend/screen/modal/OK/screen.zig setState.
/// Your arguments are the values assigned to each Params member.
pub const Params = struct {
    allocator: std.mem.Allocator,

    // Parameters.
    heading: []const u8, // The dialog title.
    message: []const u8, // The dialog message.

    /// The caller owns the returned value.
    pub fn init(allocator: std.mem.Allocator, heading: []const u8, message: []const u8) !*Params {
        var args: *Params = try allocator.create(Params);
        args.allocator = allocator;
        args.heading = try allocator.alloc(u8, heading.len);
        errdefer {
            allocator.destroy(args);
        }
        args.message = try allocator.alloc(u8, message.len);
        errdefer {
            allocator.free(args.heading);
            allocator.destroy(args);
        }
        @memcpy(@constCast(args.heading), heading);
        @memcpy(@constCast(args.message), message);
        return args;
    }

    pub fn deinit(self: *Params) void {
        self.allocator.free(self.heading);
        self.allocator.free(self.message);
        self.allocator.destroy(self);
    }
};
