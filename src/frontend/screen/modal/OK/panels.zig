const std = @import("std");
const dvui = @import("dvui");

const _OK_ = @import("OK_panel.zig");
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
    OK: ?*_OK_.Panel,

    pub fn deinit(self: *Panels) void {
        if (self.OK) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        const result = switch (self.current_panel_tag) {
            .OK => self.OK.?.frame(allocator),
            .none => self.OK.?.frame(allocator),
        };
        return result;
    }

    pub fn setCurrentToOK(self: *Panels) void {
        self.current_panel_tag = PanelTags.OK;
    }

    pub fn presetModal(self: *Panels, modal_params: *ModalParams) !void {
        try self.OK.presetModal(modal_params);
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, exit: ExitFn, window: *dvui.Window) !*Panels {
    var panels: *Panels = try allocator.create(Panels);
    panels.allocator = allocator;

    panels.OK = try _OK_.init(allocator, main_view, panels, exit, window);
    errdefer {
        panels.deinit();
    }

    return panels;
}