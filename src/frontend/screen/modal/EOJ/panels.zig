const std = @import("std");
const dvui = @import("dvui");

const _messenger_ = @import("messenger.zig");
const _EOJ_ = @import("EOJ_panel.zig");
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
    EOJ: ?*_EOJ_.Panel,

    pub fn deinit(self: *Panels) void {
        if (self.EOJ) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        const result = switch (self.current_panel_tag) {
            .EOJ => self.EOJ.?.frame(allocator),
            .none => self.EOJ.?.frame(allocator),
        };
        return result;
    }

    pub fn setCurrentToEOJ(self: *Panels) void {
        self.current_panel_tag = PanelTags.EOJ;
    }

    pub fn presetModal(self: *Panels, modal_params: *ModalParams) !void {
        try self.EOJ.presetModal(modal_params);
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, messenger: *_messenger_.Messenger, exit: ExitFn, window: *dvui.Window) !*Panels {
    var panels: *Panels = try allocator.create(Panels);
    panels.allocator = allocator;

    panels.EOJ = try _EOJ_.init(allocator, main_view, panels, messenger, exit, window);
    errdefer {
        panels.deinit();
    }

    return panels;
}