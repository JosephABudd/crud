const std = @import("std");

/// Params is the parameters for the YesNo modal screen's state.
/// See src/frontend/screen/modal/YesNo/screen.zig setState.
/// Your arguments are the values assigned to each Params member.
/// For examples:
/// * See OK.zig for a Params example.
/// * See src/frontend/screen/modal/OK/screen.zig setState.
pub const Params = struct {
    allocator: std.mem.Allocator,

    // Parameters.
    heading: []const u8,
    question: []const u8,
    yes_label: []const u8,
    no_label: []const u8,
    implementor: *anyopaque,
    yes_fn: *const fn (implementor: *anyopaque) void,
    no_fn: ?*const fn (implementor: *anyopaque) void,

    /// The caller owns the returned value.
    pub fn init(
        allocator: std.mem.Allocator,
        heading: []const u8,
        question: []const u8,
        yes_label: []const u8,
        no_label: []const u8,
        implementor: *anyopaque,
        yes_fn: *const fn (implementor: *anyopaque) void,
        no_fn: ?*const fn (implementor: *anyopaque) void,
    ) !*Params {
        var args: *Params = try allocator.create(Params);
        args.allocator = allocator;
        args.heading = try allocator.alloc(u8, heading.len);
        @memcpy(@constCast(args.heading), heading);
        args.question = try allocator.alloc(u8, question.len);
        @memcpy(@constCast(args.question), question);
        args.implementor = implementor;
        args.yes_label = try allocator.alloc(u8, yes_label.len);
        @memcpy(@constCast(args.yes_label), yes_label);
        args.no_label = try allocator.alloc(u8, no_label.len);
        @memcpy(@constCast(args.no_label), no_label);
        args.yes_fn = yes_fn;
        args.no_fn = no_fn;
        return args;
    }

    pub fn deinit(self: *Params) void {
        self.allocator.free(self.heading);
        self.allocator.free(self.question);
        self.allocator.free(self.yes_label);
        self.allocator.free(self.no_label);
        self.allocator.destroy(self);
    }
};
