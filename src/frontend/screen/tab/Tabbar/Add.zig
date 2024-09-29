const std = @import("std");
const dvui = @import("dvui");

const Content = @import("various").Content;
const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const Messenger = @import("view/messenger.zig").Messenger;
const ScreenOptions = @import("screen.zig").Options;
pub const PanelView = @import("view/Add.zig").View;
const ViewOptions = @import("view/Add.zig").Options;

/// Add panel.
/// This panel is the content for this screen's Add tab.
/// This screen's Add tab is this panel's container.
pub const Panel = struct {
    allocator: std.mem.Allocator, // For persistant state data.
    view: *PanelView,

    pub const View = PanelView;

    pub const Options = ViewOptions;

    pub fn init(
        allocator: std.mem.Allocator,
        window: *dvui.Window,
        main_view: *MainView,
        messenger: *Messenger,
        exit: ExitFn,
        screen_options: ScreenOptions,
    ) !*Panel {
        var self: *Panel = try allocator.create(Panel);
        self.allocator = allocator;
        _ = screen_options;
        self.view = try PanelView.init(
            allocator,
            window,
            main_view,
            messenger,
            exit,
            // KICKZIG TODO:
            // The next value is the ViewOptions which you may want to modify using the param screen_settings.
            // You may want to use param screen_settings to modify the value of the ViewOptions.
            .{},
        );
        errdefer allocator.destroy(self);
        return self;
    }

    // Content interface functions.

    /// Convert this Panel to a Content interface.
    pub fn asContent(self: *Panel) !*Content {
        return try Content.init(
            self.allocator,
            self,
            Panel.deinitContentFn,
            Panel.frameContentFn,
            Panel.labelContentFn,
            Panel.willFrameContentFn,
            Panel.setContainerFn,
        );
    }

    pub fn deinit(self: *Panel) void {
        // This panel is deinited by the container.
        // So don't deinit the container.
        self.view.deinit();
        self.allocator.destroy(self);
    }

    /// When a container closes it deinits.
    /// When a container deinits, it deinits it's content.
    pub fn deinitContentFn(implementor: *anyopaque) void {
        var self: *Panel = @alignCast(@ptrCast(implementor));
        self.deinit();
    }

    /// Called by the container when it frames.
    /// When a container frames, it frames it's content.
    pub fn frameContentFn(implementor: *anyopaque, arena: std.mem.Allocator) anyerror!void {
        var self: *Panel = @alignCast(@ptrCast(implementor));
        try self.view.frame(arena);
    }

    /// Called by the container when it refreshes.
    /// When a container refreshes, it refreshes it's label.
    /// The caller owns the returned value.
    pub fn labelContentFn(implementor: *anyopaque, arena: std.mem.Allocator) anyerror![]const u8 {
        var self: *Panel = @alignCast(@ptrCast(implementor));
        return self.view.label(arena);
    }

    /// Called by the container.
    /// Returns if this content will frame under current state.
    /// A container will not frame if it's content will not frame.
    pub fn willFrameContentFn(implementor: *anyopaque) bool {
        var self: *Panel = @alignCast(@ptrCast(implementor));
        return self.view.willFrame();
    }

    /// Called by the container when it inits.
    /// The container sets this panel as it's content.
    /// The container sets itself as this panel's container.
    pub fn setContainerFn(implementor: *anyopaque, container: *Container) !void {
        var self: *Panel = @alignCast(@ptrCast(implementor));
        if (self.view.container != null) {
            return error.ContainerAlreadySet;
        }
        self.view.container = container;
    }

    /// Called by the messenger.
    /// Closes the container.
    pub fn close(self: *Panel) void {
        self.view.container.close();
    }

    /// Called by the messenger.
    /// Resets the state using the not null values in values.
    /// Then it refreshes for the next frame.
    /// The caller owns settings.
    pub fn setState(self: *Panel, settings: ViewOptions) !void {
        return self.view.setState(settings);
    }

    /// See view/{0s}.zig fn setState.
    /// The caller owns the return value.
    pub fn getState(self: *Panel) !*ViewOptions {{
        return self.view.getState();
    }}
};