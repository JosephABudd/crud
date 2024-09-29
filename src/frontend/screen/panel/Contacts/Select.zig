const std = @import("std");
const dvui = @import("dvui");

const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const Messenger = @import("view/messenger.zig").Messenger;
const Panels = @import("panels.zig").Panels;
const ScreenOptions = @import("screen.zig").Options;
const PanelView = @import("view/Select.zig").View;
const ViewOptions = @import("view/Select.zig").Options;

/// This panel is never a Content but it's screen is.
pub const Panel = struct {
    allocator: std.mem.Allocator, // For persistant state data.
    view: ?*PanelView,

    pub const View = PanelView;

    pub const Options = ViewOptions;

    pub fn init(
        allocator: std.mem.Allocator,
        window: *dvui.Window,
        main_view: *MainView,
        all_panels: *Panels,
        messenger: *Messenger,
        exit: ExitFn,
        container: ?*Container,
        screen_options: ScreenOptions,
    ) !*Panel {
        var self: *Panel = try allocator.create(Panel);
        self.allocator = allocator;
        self.view = try PanelView.init(
            allocator,
            window,
            main_view,
            container,
            all_panels,
            messenger,
            exit,
            screen_options,
        );
        errdefer {
            self.view = null;
            self.deinit();
        }
        return self;
    }

    pub fn deinit(self: *Panel) void {
        if (self.view) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }
};