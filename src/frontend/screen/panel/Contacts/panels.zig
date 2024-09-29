const std = @import("std");
const dvui = @import("dvui");

const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;
const Messenger = @import("view/messenger.zig").Messenger;
const MainView = @import("framers").MainView;
const ScreenOptions = @import("screen.zig").Options;

const AddPanel = @import("Add.zig").Panel;
const SelectPanel = @import("Select.zig").Panel;
const RemovePanel = @import("Remove.zig").Panel;
const EditPanel = @import("Edit.zig").Panel;

const PanelTags = enum {
    Add,
    Select,
    Remove,
    Edit,
    none,
};

pub const Panels = struct {
    allocator: std.mem.Allocator,
    Add: ?*AddPanel,
    Select: ?*SelectPanel,
    Remove: ?*RemovePanel,
    Edit: ?*EditPanel,
    current_panel_tag: PanelTags,

    pub fn deinit(self: *Panels) void {
        if (self.Add) |member| {
            member.deinit();
        }
        if (self.Select) |member| {
            member.deinit();
        }
        if (self.Remove) |member| {
            member.deinit();
        }
        if (self.Edit) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        return switch (self.current_panel_tag) {
            .Add => self.Add.?.view.?.frame(allocator),
            .Select => self.Select.?.view.?.frame(allocator),
            .Remove => self.Remove.?.view.?.frame(allocator),
            .Edit => self.Edit.?.view.?.frame(allocator),
            .none => self.Add.?.view.?.frame(allocator),
        };
    }

    pub fn refresh(self: *Panels) void {
        switch (self.current_panel_tag) {
            .Add => self.Add.?.view.?.refresh(),
            .Select => self.Select.?.view.?.refresh(),
            .Remove => self.Remove.?.view.?.refresh(),
            .Edit => self.Edit.?.view.?.refresh(),
            .none => self.Add.?.view.?.refresh(),
        }
    }

    pub fn setCurrentToAdd(self: *Panels) void {
        self.current_panel_tag = PanelTags.Add;
    }

    pub fn setCurrentToSelect(self: *Panels) void {
        self.current_panel_tag = PanelTags.Select;
    }

    pub fn setCurrentToRemove(self: *Panels) void {
        self.current_panel_tag = PanelTags.Remove;
    }

    pub fn setCurrentToEdit(self: *Panels) void {
        self.current_panel_tag = PanelTags.Edit;
    }

    pub fn setContainer(self: *Panels, container: *Container) !void {
        try self.Add.?.view.?.setContainer(container);
        try self.Select.?.view.?.setContainer(container);
        try self.Remove.?.view.?.setContainer(container);
        try self.Edit.?.view.?.setContainer(container);
    }

    pub fn init(
        allocator: std.mem.Allocator,
        main_view: *MainView,
        messenger: *Messenger,
        exit: ExitFn,
        window: *dvui.Window,
        container: ?*Container,
        screen_options: ScreenOptions,
    ) !*Panels {
        var panels: *Panels = try allocator.create(Panels);
        panels.allocator = allocator;

        panels.Add = try AddPanel.init(
            allocator,
            window,
            main_view,
            panels,
            messenger,
            exit,
            container,
            screen_options,
        );
        errdefer panels.deinit();

        panels.Select = try SelectPanel.init(
            allocator,
            window,
            main_view,
            panels,
            messenger,
            exit,
            container,
            screen_options,
        );
        errdefer panels.deinit();

        panels.Remove = try RemovePanel.init(
            allocator,
            window,
            main_view,
            panels,
            messenger,
            exit,
            container,
            screen_options,
        );
        errdefer panels.deinit();

        panels.Edit = try EditPanel.init(
            allocator,
            window,
            main_view,
            panels,
            messenger,
            exit,
            container,
            screen_options,
        );
        errdefer panels.deinit();

        return panels;
    }
};
