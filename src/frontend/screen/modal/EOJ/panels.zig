const std = @import("std");
const dvui = @import("dvui");

const EOJPanel = @import("EOJ.zig").Panel;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").EOJ;

const PanelTags = enum {
    EOJ,
    none,
};

pub const Panels = struct {
    allocator: std.mem.Allocator,
    current_panel_tag: PanelTags,
    EOJ: ?*EOJPanel,

    pub fn deinit(self: *Panels) void {
        if (self.EOJ) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        return switch (self.current_panel_tag) {
            .EOJ => self.EOJ.?.frame(allocator),
            .none => self.EOJ.?.frame(allocator),
        };
    }

    pub fn borderColorCurrent(self: *Panels) dvui.Options.ColorOrName {
        return switch (self.current_panel_tag) {
            .EOJ => self.EOJ.?.view.?.border_color,
            .none => self.EOJ.?.view.?.border_color,
        };
    }

    pub fn setCurrentToEOJ(self: *Panels) void {
        self.current_panel_tag = PanelTags.EOJ;
    }

    pub fn presetModal(self: *Panels, modal_params: *ModalParams) !void {
        try self.EOJ.?.presetModal(modal_params);
    }

    pub fn init(allocator: std.mem.Allocator, main_view: *MainView, exit: ExitFn, window: *dvui.Window, theme: *dvui.Theme) !*Panels {
        var panels: *Panels = try allocator.create(Panels);
        panels.allocator = allocator;

        panels.EOJ = try EOJPanel.init(allocator, main_view, panels, exit, window, theme);
        errdefer panels.deinit();

        return panels;
    }
};
