const std = @import("std");
const dvui = @import("dvui");

const _channel_ = @import("channel");
const _messenger_ = @import("messenger.zig");
const _panels_ = @import("panels.zig");
const _startup_ = @import("startup");
const _various_ = @import("various");
const MainView = @import("framers").MainView;

pub const Screen = struct {
    allocator: std.mem.Allocator,
    main_view: *MainView,
    all_panels: ?*_panels_.Panels,
    messenger: ?*_messenger_.Messenger,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,
    container: ?*_various_.Container,
    only_frame_in_container: bool,

    /// init constructs this self, subscribes it to main_view and returns the error.
    pub fn init(startup: _startup_.Frontend) !*Screen {
        var self: *Screen = try startup.allocator.create(Screen);
        self.allocator = startup.allocator;
        self.main_view = startup.main_view;
        self.receive_channels = startup.receive_channels;
        self.send_channels = startup.send_channels;
        self.container = null;
        self.only_frame_in_container = false;

        // The messenger.
        self.messenger = try _messenger_.init(startup.allocator, startup.main_view, startup.send_channels, startup.receive_channels, startup.exit);
        errdefer {
            self.deinit();
        }

        // All of the panels.
        self.all_panels = try _panels_.init(startup.allocator, startup.main_view, self.messenger.?, startup.exit, startup.window);
        errdefer {
            self.deinit();
        }
        self.messenger.?.all_panels = self.all_panels.?;
        // The Select panel is the default.
        self.all_panels.?.setCurrentToSelect();
        return self;
    }

    pub fn deinit(self: *Screen) void {
        if (self.container) |member| {
            member.deinit();
        }
        if (self.messenger) |member| {
            member.deinit();
        }
        if (self.all_panels) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    /// refresh only if this screen is showing.
    pub fn refresh(self: *Screen) void {
        if (self.container) |container| {
            // This screen is framing inside a container.
            // That container is framing inside the main view.
            // Refresh the container.
            // The container which is another type of screen, will refresh only if it is the currently viewed screen inside the main view.
            container.refresh();
        } else {
            // This screen is framing inside the main view.
            // Main view will refresh only if this is the currently viewed screen.
            self.main_view.refreshRemove();
        }
    }

    /// If container is not null then this screen is running inside a container.
    /// Containers run inside the main view.
    pub fn setContainer(self: *Screen, container: *_various_.Container) void {
        self.container = container;
        self.all_panels.?.setContainer(container);
    }

    pub fn willFrame(self: *Screen) bool {
        return switch (self.only_frame_in_container) {
            true => blk: {
                // This screen will not frame inside the main view.
                // This screen will only frame inside a container which frames inside the main view.
                break :blk (self.container != null);
            },
            false => blk: {
                // This screen will frame:
                // 1. inside the main view.
                // 2. inside a container.
                break :blk true;
            },
        };
    }

    /// The caller does not own the returned value.
    /// KICKZIG TODO: You may want to edit the returned label.
    /// The label is displayed in the main menu only.
    pub fn label(_: *Screen) []const u8 {
        return "Contacts";
    }

    pub fn frame(self: *Screen, arena: std.mem.Allocator) !void {
        try self.all_panels.?.frameCurrent(arena);
    }

    // Container functions.

    /// When a container refreshes it calls labelFn.
    pub fn labelFn(implementor: *anyopaque) anyerror![]const u8 {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        return self.label();
    }

    /// When a container refreshes it calls refreshFn.
    pub fn refreshFn(implementor: *anyopaque) void {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        self.all_panels.?.refresh();
    }

    /// When a container frames it calls frameFn.
    pub fn frameFn(implementor: *anyopaque, arena: std.mem.Allocator) anyerror!void {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        return self.frame(arena);
    }

    /// When a container deinits it calls deinitFn.
    pub fn deinitFn(implementor: *anyopaque) void {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        self.deinit();
    }
};