const std = @import("std");
const dvui = @import("dvui");

const Messenger = @import("view/messenger.zig").Messenger;
const ChoicePanel = @import("Choice.zig").Panel;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").Choice;

const PanelTags = enum {
    Choice,
    none,
};

pub const Panels = struct {
    allocator: std.mem.Allocator,
    current_panel_tag: PanelTags,
    Choice: ?*ChoicePanel,

    pub fn deinit(self: *Panels) void {
        if (self.Choice) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        return switch (self.current_panel_tag) {
            .Choice => self.Choice.?.frame(allocator),
            .none => self.Choice.?.frame(allocator),
        };
    }

    pub fn borderColorCurrent(self: *Panels) dvui.Options.ColorOrName {
        return switch (self.current_panel_tag) {
            .Choice => self.Choice.?.view.?.border_color,
            .none => self.Choice.?.view.?.border_color,
        };
    }

    pub fn setCurrentToChoice(self: *Panels) void {
        self.current_panel_tag = PanelTags.Choice;
    }

    pub fn presetModal(self: *Panels, modal_params: *ModalParams) !void {
        try self.Choice.?.presetModal(modal_params);
    }

    pub fn init(allocator: std.mem.Allocator, main_view: *MainView, messenger: *Messenger, exit: ExitFn, window: *dvui.Window, theme: *dvui.Theme) !*Panels {
        var panels: *Panels = try allocator.create(Panels);
        panels.allocator = allocator;

        panels.Choice = try ChoicePanel.init(allocator, main_view, panels, messenger, exit, window, theme);
        errdefer panels.deinit();

        return panels;
    }
};
