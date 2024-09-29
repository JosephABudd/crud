const std = @import("std");
const dvui = @import("dvui");

const YesNoPanel = @import("YesNo.zig").Panel;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").YesNo;

const PanelTags = enum {
    YesNo,
    none,
};

pub const Panels = struct {
    allocator: std.mem.Allocator,
    current_panel_tag: PanelTags,
    YesNo: ?*YesNoPanel,

    pub fn deinit(self: *Panels) void {
        if (self.YesNo) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        return switch (self.current_panel_tag) {
            .YesNo => self.YesNo.?.frame(allocator),
            .none => self.YesNo.?.frame(allocator),
        };
    }

    pub fn borderColorCurrent(self: *Panels) dvui.Options.ColorOrName {
        return switch (self.current_panel_tag) {
            .YesNo => self.YesNo.?.view.?.border_color,
            .none => self.YesNo.?.view.?.border_color,
        };
    }

    pub fn setCurrentToYesNo(self: *Panels) void {
        self.current_panel_tag = PanelTags.YesNo;
    }

    pub fn presetModal(self: *Panels, modal_params: *ModalParams) !void {
        try self.YesNo.?.presetModal(modal_params);
    }

    pub fn init(allocator: std.mem.Allocator, main_view: *MainView, exit: ExitFn, window: *dvui.Window, theme: *dvui.Theme) !*Panels {
        var panels: *Panels = try allocator.create(Panels);
        panels.allocator = allocator;

        panels.YesNo = try YesNoPanel.init(allocator, main_view, panels, exit, window, theme);
        errdefer panels.deinit();

        return panels;
    }
};
