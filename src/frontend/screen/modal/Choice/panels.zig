const std = @import("std");
const dvui = @import("dvui");

const _messenger_ = @import("messenger.zig");
const _Choice_ = @import("Choice_panel.zig");
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
    Choice: ?*_Choice_.Panel,

    pub fn deinit(self: *Panels) void {
        if (self.Choice) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        const result = switch (self.current_panel_tag) {
            .Choice => self.Choice.?.frame(allocator),
            .none => self.Choice.?.frame(allocator),
        };
        return result;
    }

    pub fn setCurrentToChoice(self: *Panels) void {
        self.current_panel_tag = PanelTags.Choice;
    }

    pub fn presetModal(self: *Panels, modal_params: *ModalParams) !void {
        try self.Choice.presetModal(modal_params);
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, messenger: *_messenger_.Messenger, exit: ExitFn, window: *dvui.Window) !*Panels {
    var panels: *Panels = try allocator.create(Panels);
    panels.allocator = allocator;

    panels.Choice = try _Choice_.init(allocator, main_view, panels, messenger, exit, window);
    errdefer {
        panels.deinit();
    }

    return panels;
}