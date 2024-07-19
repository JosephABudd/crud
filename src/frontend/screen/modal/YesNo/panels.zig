const std = @import("std");
const dvui = @import("dvui");

const _YesNo_ = @import("YesNo_panel.zig");
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
    YesNo: ?*_YesNo_.Panel,

    pub fn deinit(self: *Panels) void {
        if (self.YesNo) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        const result = switch (self.current_panel_tag) {
            .YesNo => self.YesNo.?.frame(allocator),
            .none => self.YesNo.?.frame(allocator),
        };
        return result;
    }

    pub fn setCurrentToYesNo(self: *Panels) void {
        self.current_panel_tag = PanelTags.YesNo;
    }

    pub fn presetModal(self: *Panels, modal_params: *ModalParams) !void {
        try self.YesNo.presetModal(modal_params);
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, exit: ExitFn, window: *dvui.Window) !*Panels {
    var panels: *Panels = try allocator.create(Panels);
    panels.allocator = allocator;

    panels.YesNo = try _YesNo_.init(allocator, main_view, panels, exit, window);
    errdefer {
        panels.deinit();
    }

    return panels;
}