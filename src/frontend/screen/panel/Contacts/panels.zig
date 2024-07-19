const std = @import("std");
const dvui = @import("dvui");

const _framers_ = @import("framers");
const _messenger_ = @import("messenger.zig");
const _various_ = @import("various");
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const _Edit_ = @import("Edit_panel.zig");
const _Add_ = @import("Add_panel.zig");
const _Remove_ = @import("Remove_panel.zig");
const _Select_ = @import("Select_panel.zig");

const PanelTags = enum {
    Edit,
    Add,
    Remove,
    Select,
    none,
};

pub const Panels = struct {
    allocator: std.mem.Allocator,
    Edit: ?*_Edit_.Panel,
    Add: ?*_Add_.Panel,
    Remove: ?*_Remove_.Panel,
    Select: ?*_Select_.Panel,
    current_panel_tag: PanelTags,

    pub fn deinit(self: *Panels) void {
        if (self.Edit) |Edit| {
            Edit.deinit();
        }
        if (self.Add) |Add| {
            Add.deinit();
        }
        if (self.Remove) |Remove| {
            Remove.deinit();
        }
        if (self.Select) |Select| {
            Select.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        return switch (self.current_panel_tag) {
            .Edit => self.Edit.?.frame(allocator),
            .Add => self.Add.?.frame(allocator),
            .Remove => self.Remove.?.frame(allocator),
            .Select => self.Select.?.frame(allocator),
            .none => self.Edit.?.frame(allocator),
        };
    }

    pub fn refresh(self: *Panels) void {
        switch (self.current_panel_tag) {
            .Edit => self.Edit.?.refresh(),
            .Add => self.Add.?.refresh(),
            .Remove => self.Remove.?.refresh(),
            .Select => self.Select.?.refresh(),
            .none => self.Edit.?.refresh(),
        }
    }

    pub fn setCurrentToEdit(self: *Panels) void {
        self.current_panel_tag = PanelTags.Edit;
    }

    pub fn setCurrentToAdd(self: *Panels) void {
        self.current_panel_tag = PanelTags.Add;
    }

    pub fn setCurrentToRemove(self: *Panels) void {
        self.current_panel_tag = PanelTags.Remove;
    }

    pub fn setCurrentToSelect(self: *Panels) void {
        self.current_panel_tag = PanelTags.Select;
    }

    pub fn setContainer(self: *Panels, container: *_various_.Container) void {
        self.Edit.?.setContainer(container);
        self.Add.?.setContainer(container);
        self.Remove.?.setContainer(container);
        self.Select.?.setContainer(container);
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, messenger: *_messenger_.Messenger, exit: ExitFn, window: *dvui.Window) !*Panels {
    var panels: *Panels = try allocator.create(Panels);
    panels.allocator = allocator;
    panels.Edit = try _Edit_.init(allocator, main_view, panels, messenger, exit, window);
    errdefer panels.deinit();
    panels.Add = try _Add_.init(allocator, main_view, panels, messenger, exit, window);
    errdefer panels.deinit();
    panels.Remove = try _Remove_.init(allocator, main_view, panels, messenger, exit, window);
    errdefer panels.deinit();
    panels.Select = try _Select_.init(allocator, main_view, panels, messenger, exit, window);
    errdefer panels.deinit();

    return panels;
}
