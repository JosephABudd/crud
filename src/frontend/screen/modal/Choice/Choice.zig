const std = @import("std");
const dvui = @import("dvui");

const _channel_ = @import("channel");

const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const Messenger = @import("view/messenger.zig").Messenger;
const ModalParams = @import("modal_params").Choice;
const Panels = @import("panels.zig").Panels;
const View  = @import("view/Choice.zig").View;

pub const Panel = struct {
    allocator: std.mem.Allocator, // For persistant state data.
    exit: ExitFn,

    modal_params: ?*ModalParams,
    view: ?*View,

    // The screen owns the modal params.
    pub fn presetModal(self: *Panel, setup_args: *ModalParams) !void {
        // previous modal_params are already deinited by the screen.
        self.modal_params = setup_args;
    }

    pub fn init(allocator: std.mem.Allocator, main_view: *MainView, all_panels: *Panels, messenger: *Messenger, exit: ExitFn, window: *dvui.Window, theme: *dvui.Theme) !*Panel {
        var self: *Panel = try allocator.create(Panel);
        self.allocator = allocator;
        self.view = try View.init(
            allocator,
            window,
            main_view,
            all_panels,
            messenger,
            exit,
            theme,
        );
        errdefer {
            self.view = null;
            self.deinit();
        }
        self.exit = exit;
        self.modal_params = null;
        return self;
    }

    pub fn deinit(self: *Panel) void {
        // modal_params are already deinited by the screen.
        if (self.view) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    // close removes this modal screen replacing it with the previous screen.
    fn close(self: *Panel) void {
        self.main_view.hideChoice();
    }

    /// frame this panel.
    /// Layout, Draw, Handle user events.
    pub fn frame(self: *Panel, arena: std.mem.Allocator) !void {
        return self.view.?.frame(arena, self.modal_params.?);
    }

};
