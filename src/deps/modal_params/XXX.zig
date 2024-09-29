const std = @import("std");

/// Params is the parameters for the XXX modal screen's state.
/// See src/frontend/screen/modal/XXX/screen.zig setState.
/// Your arguments are the values assigned to each Params member.
/// For examples:
/// * See OK.zig for a Params example.
/// * See src/frontend/screen/modal/OK/screen.zig setState.
pub const Params = struct {
    allocator: std.mem.Allocator,

    // Parameters.

    /// The caller owns the returned value.
    pub fn init(allocator: std.mem.Allocator) !*Params {
        var args: *Params = try allocator.create(Params);
        args.allocator = allocator;
        return args;
    }

    pub fn deinit(self: *Params) void {
        self.allocator.destroy(self);
    }
};
