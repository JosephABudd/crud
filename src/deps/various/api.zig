const std = @import("std");

pub const ExitFn = *const fn (src: std.builtin.SourceLocation, err: anyerror, description: []const u8) void;

pub const Container = struct {
    allocator: std.mem.Allocator,
    implementor: *anyopaque,
    refreshFN: *const fn (implementor: *anyopaque) void,
    closeFn: *const fn (implementor: *anyopaque) void,

    pub fn close(self: *Container) void {
        self.closeFn(self.implementor);
    }

    pub fn refresh(self: *Container) void {
        self.closeFn(self.implementor);
    }

    pub fn init(
        allocator: std.mem.Allocator,
        implementor: *anyopaque,
        refreshFN: *const fn (implementor: *anyopaque) void,
        closeFn: *const fn (implementor: *anyopaque) void,
    ) !*Container {
        var self: *Container = try allocator.create(Container);
        self.allocator = allocator;
        self.implementor = implementor;
        self.refreshFN = refreshFN;
        self.closeFn = closeFn;
        return self;
    }

    pub fn deinit(self: *Container) void {
        self.allocator.destroy(self);
    }
};