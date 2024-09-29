const std = @import("std");
const dvui = @import("dvui");

const OKPanel = @import("OK.zig").Panel;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").OK;

const PanelTags = enum {
    OK,
    none,
};

pub const Panels = struct {
    allocator: std.mem.Allocator,
    current_panel_tag: PanelTags,
    OK: ?*OKPanel,

    pub fn deinit(self: *Panels) void {
        if (self.OK) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        return switch (self.current_panel_tag) {
            .OK => self.OK.?.frame(allocator),
            .none => self.OK.?.frame(allocator),
        };
    }

    pub fn borderColorCurrent(self: *Panels) dvui.Options.ColorOrName {
        return switch (self.current_panel_tag) {
            .OK => self.OK.?.view.?.border_color,
            .none => self.OK.?.view.?.border_color,
        };
    }

    pub fn setCurrentToOK(self: *Panels) void {
        self.current_panel_tag = PanelTags.OK;
    }

    pub fn presetModal(self: *Panels, modal_params: *ModalParams) !void {
        try self.OK.?.presetModal(modal_params);
    }

    pub fn init(allocator: std.mem.Allocator, main_view: *MainView, exit: ExitFn, window: *dvui.Window, theme: *dvui.Theme) !*Panels {
        var panels: *Panels = try allocator.create(Panels);
        panels.allocator = allocator;

        panels.OK = try OKPanel.init(allocator, main_view, panels, exit, window, theme);
        errdefer panels.deinit();

        return panels;
    }
};
