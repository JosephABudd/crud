const std = @import("std");

const Counter = @import("counter").Counter;
pub const ExitFn = *const fn (src: std.builtin.SourceLocation, err: anyerror, description: []const u8) void;

pub const Content = struct {
    allocator: std.mem.Allocator,
    counter: *Counter,

    implementor: *anyopaque,
    deinit_fn: *const fn (implementor: *anyopaque) void,
    will_frame_fn: *const fn (implementor: *anyopaque) bool,
    frame_fn: *const fn (implementor: *anyopaque, arena: std.mem.Allocator) anyerror!void,
    label_fn: *const fn (implementor: *anyopaque, arena: std.mem.Allocator) anyerror![]const u8,
    set_container_fn: *const fn (implementor: *anyopaque, container: *Container) anyerror!void,

    // param implementor is owned by the Content.
    pub fn init(
        allocator: std.mem.Allocator,
        implementor: *anyopaque,
        deinit_fn: *const fn (implementor: *anyopaque) void,
        frame_fn: *const fn (implementor: *anyopaque, arena: std.mem.Allocator) anyerror!void,
        label_fn: *const fn (implementor: *anyopaque, arena: std.mem.Allocator) anyerror![]const u8,
        will_frame_fn: *const fn (implementor: *anyopaque) bool,
        set_container_fn: *const fn (implementor: *anyopaque, container: *Container) anyerror!void,
    ) !*Content {
        var self: *Content = try allocator.create(Content);
        self.counter = try Counter.init(allocator);
        errdefer allocator.destroy(self);
        _ = self.counter.inc();
        self.allocator = allocator;

        self.implementor = implementor;

        self.deinit_fn = deinit_fn;
        self.frame_fn = frame_fn;
        self.label_fn = label_fn;
        self.will_frame_fn = will_frame_fn;
        self.set_container_fn = set_container_fn;

        return self;
    }

    // deinit does not deinit self.implementor.
    // Content does not own self.implementor.
    // implementor must deinit itself.
    pub fn deinit(self: *Content) void {
        if (self.counter.dec() > 0) {
            return;
        }
        self.counter.deinit();
        self.deinit_fn(self.implementor);
        self.allocator.destroy(self);
    }

    pub fn frame(self: *Content, arena: std.mem.Allocator) anyerror!void {
        return self.frame_fn(self.implementor, arena);
    }
    pub fn label(self: *Content, allocator: std.mem.Allocator) anyerror![]const u8 {
        return self.label_fn(self.implementor, allocator);
    }
    pub fn willFrame(self: *Content) bool {
        return self.will_frame_fn(self.implementor);
    }
    pub fn setContainer(self: *Content, container: *Container) !void {
        return self.set_container_fn(self.implementor, container);
    }

    pub fn copy(self: *Content) *Content {
        _ = self.counter.inc();
        return self;
    }
};

pub const Container = struct {
    allocator: std.mem.Allocator,
    counter: *Counter,

    implementor: *anyopaque,

    /// close_fn
    /// if implementor == MainView:
    ///   * close_fn is null because app will close and deinit the implementor when app ends.
    /// if implementor == a screen_pointers.ScreenPointers.???:
    ///   * close_fn will self.container.close() because MainView is container.
    ///   * MainView is not closable until the app ends as stated above.
    /// if implementor is an instance of a screen_pointers.???:
    ///   * close_fn will self.container.close();
    /// if implementor is an instance of a Tab:
    ///   * close_fn will:
    ///     * remove the implementor (Tab) from it's Tabs.
    ///     * delete all of the implementor's (Tab's) content.
    ///     * deinit the implementor (Tab).
    close_fn: ?*const fn (implementor: *anyopaque) void,

    /// refresh_fn
    /// implementor must call self.container.refresh_fn.
    refresh_fn: *const fn (implementor: *anyopaque) void,

    /// param implementor is not owned by the Content.
    /// implementor owns itself.
    pub fn init(
        allocator: std.mem.Allocator,
        implementor: *anyopaque,
        close_fn: ?*const fn (implementor: *anyopaque) void,
        refresh_fn: *const fn (implementor: *anyopaque) void,
    ) !*Container {
        var self: *Container = try allocator.create(Container);
        self.counter = try Counter.init(allocator);
        errdefer allocator.destroy(self);
        _ = self.counter.inc();
        self.allocator = allocator;

        self.implementor = implementor;
        self.close_fn = close_fn;
        self.refresh_fn = refresh_fn;

        return self;
    }

    /// deinit this Container only.
    pub fn deinit(self: *Container) void {
        if (self.counter.dec() > 0) {
            return;
        }
        self.counter.deinit();
        self.allocator.destroy(self);
    }

    pub fn container(self: *Container) *anyopaque {
        return self.implementor;
    }

    pub fn isCloseable(self: *Container) bool {
        return (self.close_fn != null);
    }

    /// closes this container or calls it's container's fn close.
    /// If this container closes it will:
    /// * remove itself.
    /// * deinit it's content.
    /// * deinit itself.
    /// else it will call it's container's close.
    pub fn close(self: *Container) void {
        if (self.close_fn) |f| {
            f(self.implementor);
        }
    }

    // refresh refreshes the container's container.
    pub fn refresh(self: *Container) void {
        return self.refresh_fn(self.implementor);
    }

    pub fn copy(self: *Container) *Container {
        _ = self.counter.inc();
        return self;
    }
};
