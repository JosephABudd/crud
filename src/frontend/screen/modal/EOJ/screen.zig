const std = @import("std");
const dvui = @import("dvui");
const _channel_ = @import("channel");
const _panels_ = @import("panels.zig");
const _messenger_ = @import("messenger.zig");
const _startup_ = @import("startup");
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").EOJ;

pub const Screen = struct {
    allocator: std.mem.Allocator,
    main_view: *MainView,
    all_panels: ?*_panels_.Panels,
    messenger: ?*_messenger_.Messenger,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,

    /// init constructs this screen, subscribes it to startup.main_view and returns the error.
    pub fn init(startup: _startup_.Frontend) !*Screen {
        var self: *Screen = try startup.allocator.create(Screen);
        self.allocator = startup.allocator;
        self.main_view = startup.main_view;
        self.receive_channels = startup.receive_channels;
        self.send_channels = startup.send_channels;

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
        // The EOJ panel is the default.
        self.all_panels.?.setCurrentToEOJ();
        return self;
    }

    pub fn deinit(self: *Screen) void {
        if (self.messenger) |member| {
            member.deinit();
        }
        if (self.all_panels) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    /// The caller does not own the returned value.
    pub fn label(_: *Screen) []const u8 {
        return "EOJ";
    }

    pub fn frame(self: *Screen, arena: std.mem.Allocator) !void {
        try self.all_panels.?.frameCurrent(arena);
    }

    /// setState sets the state for this modal screen.
    pub fn setState(self: *Screen, setup_args: *ModalParams) !void {
        try self.all_panels.?.EOJ.?.presetModal(setup_args);
    }
};