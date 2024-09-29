const std = @import("std");
const dvui = @import("dvui");

const _channel_ = @import("channel");
const _startup_ = @import("startup");

const Container = @import("various").Container;
const Content = @import("various").Content;
const MainView = @import("framers").MainView;
const Messenger = @import("view/messenger.zig").Messenger;
const Panels = @import("panels.zig").Panels;

/// KICKZIG TODO:
/// Options will need to be customized.
/// Keep each value optional and set to null by default.
//KICKZIG TODO: Customize Options to your requirements.
pub const Options = struct {
    screen_name: ?[]const u8 = null, // Example field.

    fn copyOf(values: Options, allocator: std.mem.Allocator) !*Options {
        var copy_of: *Options = try allocator.create(Options);
        // Null optional members for fn reset.
        copy_of.screen_name = null;
        try copy_of.reset(allocator, values);
        errdefer copy_of.deinit();
        return copy_of;
    }

    fn deinit(self: *Options, allocator: std.mem.Allocator) void {
        // Screen name.
        if (self.screen_name) |member| {
            allocator.free(member);
        }
        allocator.destroy(self);
    }

    fn reset(
        self: *Options,
        allocator: std.mem.Allocator,
        settings: Options,
    ) !void {
        return self._reset(
            allocator,
            settings.screen_name,
        );
    }

    fn _reset(
        self: *Options,
        allocator: std.mem.Allocator,
        screen_name: ?[]const u8,
    ) !void {
        // Screen name.
        if (screen_name) |reset_value| {
            if (self.screen_name) |value| {
                allocator.free(value);
            }
            self.screen_name = try allocator.alloc(u8, reset_value.len);
            errdefer {
                self.screen_name = null;
                self.deinit();
            }
            @memcpy(@constCast(self.screen_name.?), reset_value);
        }
    }
};

///The Remove screen is a panel screen.
///Panel screens function by showing only one panel at a time.
///Panel screens are always content and so they implement Content.
///You can:
/// 1. Put this screen in the main menu. Add .Remove to pub const sorted_main_menu_screen_tags in src/deps/main_menu/api.zig.
/// 2. Use this screen as content for a tab. Example: kickzig add-tab «new-screen-name» *Remove «another-tab-name» ...
///
pub const Screen = struct {
    allocator: std.mem.Allocator,
    main_view: *MainView,
    all_panels: ?*Panels,
    messenger: ?*Messenger,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,
    container: ?*Container,
    state: ?*Options,

    const default_settings = Options{
        .screen_name = "Remove",
    };
    /// init constructs this self, subscribes it to main_view and returns the error.
    pub fn init(
        startup: _startup_.Frontend,
        container: ?*Container,
        screen_options: Options,
    ) !*Screen {
        var self: *Screen = try startup.allocator.create(Screen);
        self.allocator = startup.allocator;
        self.main_view = startup.main_view;
        self.receive_channels = startup.receive_channels;
        self.send_channels = startup.send_channels;

        self.state = Options.copyOf(default_settings, startup.allocator) catch |err| {
            self.state = null;
            self.deinit();
            return err;
        };
        try self.state.?.reset(startup.allocator, screen_options);
        errdefer self.deinit();
        // The messenger.
        self.messenger = try Messenger.init(startup.allocator, startup.main_view, startup.send_channels, startup.receive_channels, startup.exit, screen_options);
        errdefer {
            self.deinit();
        }

        // All of the panels.
        self.all_panels = try Panels.init(startup.allocator, startup.main_view, self.messenger.?, startup.exit, startup.window, container, screen_options);
        errdefer self.deinit();

        self.messenger.?.all_panels = self.all_panels.?;
        // The Select panel is the default.
        self.all_panels.?.setCurrentToSelect();
        self.container = container;
        return self;
    }

    pub fn deinit(self: *Screen) void {
        if (self.state) |state| {
            state.deinit(self.allocator);
        }
        // A screen is deinited by it's container or by a failed init.
        // So don't deinit the container.
        if (self.messenger) |member| {
            member.deinit();
        }
        if (self.all_panels) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    /// The caller owns the returned value.
    pub fn label(self: *Screen, allocator: std.mem.Allocator) ![]const u8 {
        return try std.fmt.allocPrint(allocator, "{s}", .{self.state.?.screen_name.?});
    }

    pub fn frame(self: *Screen, arena: std.mem.Allocator) !void {
        try self.all_panels.?.frameCurrent(arena);
    }

    fn setContainer(self: *Screen, container: *Container) !void {
        self.container = container;
        return self.all_panels.?.setContainer(container);
    }

    /// KICKZIG TODO: You may find a reason to modify willFrame.
    pub fn willFrame(self: *Screen) bool {
        return self.all_panels.?.Select.?.view.?.hasList();
    }

    // Content functions.

    /// Convert this Screen to a Content interface.
    pub fn asContent(self: *Screen) !*Content {
        return Content.init(
            self.allocator,
            self,

            Screen.deinitContentFn,
            Screen.frameContentFn,
            Screen.labelContentFn,
            Screen.willFrameContentFn,
            Screen.setContainerContentFn,
        );
    }

    /// deinitContentFn is an implementation of the Content interface.
    /// The Container calls this when it closes or deinits.
    pub fn deinitContentFn(implementor: *anyopaque) void {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        self.deinit();
    }

    /// willFrameContentFn is an implementation of the Content interface.
    /// The Container calls this when it wants to frame.
    /// Returns if this content will frame under it's current state.
    pub fn willFrameContentFn(implementor: *anyopaque) bool {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        return self.willFrame();
    }

    /// frameContentFn is an implementation of the Content interface.
    /// The Container calls this when it frames.
    pub fn frameContentFn(implementor: *anyopaque, arena: std.mem.Allocator) anyerror!void {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        return self.frame(arena);
    }

    /// labelContentFn is an implementation of the Content interface.
    /// The Container may call this when it refreshes.
    /// The caller does not own the returned value.
    pub fn labelContentFn(implementor: *anyopaque, arena: std.mem.Allocator) anyerror![]const u8 {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        return self.label(arena);
    }

    /// setContainerContentFn is an implementation of the Content interface.
    /// The Container calls this to set itself as this Content's Container.
    pub fn setContainerContentFn(implementor: *anyopaque, container: *Container) !void {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        return self.setContainer(container);
    }
};
