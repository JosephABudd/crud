const std = @import("std");
const dvui = @import("dvui");

const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;
const Messenger = @import("view/messenger.zig").Messenger;
const MainView = @import("framers").MainView;
const ScreenOptions = @import("screen.zig").Options;

const SelectPanel = @import("Select.zig").Panel;
const EditPanel = @import("Edit.zig").Panel;

const PanelTags = enum {
    Select,
    Edit,
    none,
};

pub const Panels = struct {
    allocator: std.mem.Allocator,
    Select: ?*SelectPanel,
    Edit: ?*EditPanel,
    current_panel_tag: PanelTags,

    pub fn deinit(self: *Panels) void {
        if (self.Select) |member| {
            member.deinit();
        }
        if (self.Edit) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        return switch (self.current_panel_tag) {
            .Select => self.Select.?.view.?.frame(allocator),
            .Edit => self.Edit.?.view.?.frame(allocator),
            .none => self.Select.?.view.?.frame(allocator),
        };
    }

    pub fn refresh(self: *Panels) void {
        switch (self.current_panel_tag) {
            .Select => self.Select.?.view.?.refresh(),
            .Edit => self.Edit.?.view.?.refresh(),
            .none => self.Select.?.view.?.refresh(),
        }
    }

    pub fn setCurrentToSelect(self: *Panels) void {
        self.current_panel_tag = PanelTags.Select;
    }

    pub fn setCurrentToEdit(self: *Panels) void {
        self.current_panel_tag = PanelTags.Edit;
    }

    pub fn setContainer(self: *Panels, container: *Container) !void {
        try self.Select.?.view.?.setContainer(container);
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
