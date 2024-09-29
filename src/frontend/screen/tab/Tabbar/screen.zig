const std = @import("std");
const dvui = @import("dvui");

const _channel_ = @import("channel");
const _screen_pointers_ = @import("../../../screen_pointers.zig");
const _startup_ = @import("startup");

const Messenger = @import("view/messenger.zig").Messenger;
const PanelTags = @import("panels.zig").PanelTags;
const Container = @import("various").Container;
const Content = @import("various").Content;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ScreenPointers = _screen_pointers_.ScreenPointers;
const Tab = @import("widget").Tab;
const Tabs = @import("widget").Tabs;

const AddPanel = @import("Add.zig").Panel;
const EditScreen = _screen_pointers_.Edit;
const RemoveScreen = _screen_pointers_.Remove;

/// KICKZIG TODO:
/// Options will need to be customized.
/// Keep each value optional and set to null by default.
//KICKZIG TODO: Customize Options to your requirements.
pub const Options = struct {
    screen_name: ?[]const u8 = null, // Example field.

    fn label(self: *Options, allocator: std.mem.Allocator) ![]const u8 {
        _ = self;
        return try std.fmt.allocPrint(allocator, "{s}", .{"Tabbar"});
    }

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

/// Screen is content for the main view or a container.
/// Screen is the container for Tabs.
pub const Screen = struct {
    allocator: std.mem.Allocator,
    window: *dvui.Window,
    main_view: *MainView,
    container: ?*Container,
    tabs: ?*Tabs,
    messenger: ?*Messenger,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,
    exit: ExitFn,
    screen_pointers: *ScreenPointers,
    startup: _startup_.Frontend,
    state: ?*Options,

    const default_settings = Options{
        .screen_name = "Tabbar",
    };

    pub fn AddNewAddTab(
        self: *Screen,
        selected: bool,
    ) !void {
        // The Add tab uses this screen's Add panel for content.
        const panel: *AddPanel = try AddPanel.init(
            self.allocator,
            self.window,
            self.main_view,
            self.messenger.?,
            self.exit,
            self.state.?.*,
        );
        const panel_as_content: *Content = try panel.asContent();
        errdefer panel.deinit();
        const tab: *Tab = try Tab.init(
            self.tabs.?,
            self.main_view,
            panel_as_content,
            .{
                // KICKZIG TODO:
                // You can override the options for the Add tab.
                //.closable = true,
                //.movable = true,
            },
        );
        errdefer {
            panel_as_content.deinit();
        }
        try self.tabs.?.appendTab(tab, selected);
        errdefer {
            self.allocator.destroy(tab);
            panel_as_content.deinit();
        }
    }

    pub fn AddNewEditTab(
        self: *Screen,
        selected: bool,
    ) !void {
        // The Edit tab uses the Edit screen for content.
        // The EditScreen.init second param container, is null because Tab will set it.
        // The EditScreen.init third param screen_options, is a the options for the EditScreen.
        // * KICKZIG TODO: You may find setting some screen_options to be usesful.
        // * Param screen_options has no members defined so the EditScreen will use it default settings.
        // * See screen/panel/Edit/screen.Options.
        const screen: *EditScreen = try EditScreen.init(
            self.startup,
            null,
            .{},
        );
        const screen_as_content: *Content = try screen.asContent();
        errdefer screen.deinit();
        // screen_as_content now owns screen.

        const tab: *Tab = try Tab.init(
            self.tabs.?,
            self.main_view,
            screen_as_content,
            .{
                // KICKZIG TODO:
                // You can override the options for the Edit tab.
                //.closable = true,
                //.movable = true,
            },
        );
        errdefer {
            screen_as_content.deinit();
        }
        try self.tabs.?.appendTab(tab, selected);
        errdefer {
            tab.deinit(); // will deinit screen_as_content.
        }
    }

    pub fn AddNewRemoveTab(
        self: *Screen,
        selected: bool,
    ) !void {
        // The Remove tab uses the Remove screen for content.
        // The RemoveScreen.init second param container, is null because Tab will set it.
        // The RemoveScreen.init third param screen_options, is a the options for the RemoveScreen.
        // * KICKZIG TODO: You may find setting some screen_options to be usesful.
        // * Param screen_options has no members defined so the RemoveScreen will use it default settings.
        // * See screen/panel/Remove/screen.Options.
        const screen: *RemoveScreen = try RemoveScreen.init(
            self.startup,
            null,
            .{},
        );
        const screen_as_content: *Content = try screen.asContent();
        errdefer screen.deinit();
        // screen_as_content now owns screen.

        const tab: *Tab = try Tab.init(
            self.tabs.?,
            self.main_view,
            screen_as_content,
            .{
                // KICKZIG TODO:
                // You can override the options for the Remove tab.
                //.closable = true,
                //.movable = true,
            },
        );
        errdefer {
            screen_as_content.deinit();
        }
        try self.tabs.?.appendTab(tab, selected);
        errdefer {
            tab.deinit(); // will deinit screen_as_content.
        }
    }


    /// init constructs this screen, subscribes it to all_screens and returns the error.
    /// Param tabs_options is a Tabs.Options.
    pub fn init(
        startup: _startup_.Frontend,
        container: ?*Container,
        tabs_options: Tabs.Options,
        screen_options: Options,
    ) !*Screen {
        var self: *Screen = try startup.allocator.create(Screen);
        self.allocator = startup.allocator;
        self.main_view = startup.main_view;
        self.receive_channels = startup.receive_channels;
        self.send_channels = startup.send_channels;
        self.screen_pointers = startup.screen_pointers;
        self.window = startup.window;
        self.startup = startup;

        self.state = Options.copyOf(default_settings, startup.allocator) catch |err| {
            self.state = null;
            self.deinit();
            return err;
        };
        try self.state.?.reset(startup.allocator, screen_options);
        errdefer self.deinit();

        const self_as_container: *Container = try self.asContainer();
        errdefer startup.allocator.destroy(self);

        self.tabs = try Tabs.init(startup, self_as_container, tabs_options);
        errdefer self.deinit();


        // Create the messenger.
        self.messenger = try Messenger.init(
            startup.allocator,
            self.tabs.?,
            startup.main_view,
            startup.send_channels,
            startup.receive_channels,
            startup.exit,
            self.state.?.*,
        );
        errdefer self.deinit();

        // Create 1 of each type of tab.

        try self.AddNewAddTab(true);
        errdefer self.deinit();

        try self.AddNewEditTab(false);
        errdefer self.deinit();

        try self.AddNewRemoveTab(false);
        errdefer self.deinit();
        self.container = container;
        return self;
    }

    pub fn willFrame(self: *Screen) bool {
        return self.tabs.?.willFrame();
    }

    pub fn close(self: *Screen) bool {
        _ = self;
    }

    pub fn deinit(self: *Screen) void {
        // A screen is deinited by it's container or by a failed init.
        // So don't deinit the container.
        if (self.messenger) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    /// The caller owns the returned value.
    pub fn label(self: *Screen, arena: std.mem.Allocator) ![]const u8 {
        return self.state.?.label(arena);
    }

    pub fn frame(self: *Screen, arena: std.mem.Allocator) !void {
        try self.tabs.?.frame(arena);
    }

    pub fn setContainer(self: *Screen, container: *Container) void {
        self.container = container;
    }

    // Content interface functions.

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

    /// setContainerContentFn is an implementation of the Content interface.
    /// The Container calls this to set itself as this Content's Container.
    pub fn setContainerContentFn(implementor: *anyopaque, container: *Container) !void {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        return self.setContainer(container);
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
    pub fn labelContentFn(implementor: *anyopaque, arena: std.mem.Allocator) anyerror![]const u8 {
        var self: *Screen = @alignCast(@ptrCast(implementor));
        return self.label(arena);
    }

    // Container interface functions.

    /// Convert this Screen to a Container interface.
    pub fn asContainer(self: *Screen) anyerror!*Container {
        return Container.init(
            self.allocator,
            self,
            Screen.closeContainerFn,
            Screen.refreshContainerFn,
        );
    }

    /// Close the top container.
    pub fn closeContainerFn(implementor: *anyopaque) void {
        const self: *Screen = @alignCast(@ptrCast(implementor));
        self.container.?.close();
    }

    /// Refresh a container up to dvui.window if visible.
    pub fn refreshContainerFn(implementor: *anyopaque) void {
        const self: *Screen = @alignCast(@ptrCast(implementor));
        self.container.?.refresh();
    }
};

