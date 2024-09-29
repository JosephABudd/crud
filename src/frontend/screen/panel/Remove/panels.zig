const std = @import("std");
const dvui = @import("dvui");

const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;
const Messenger = @import("view/messenger.zig").Messenger;
const MainView = @import("framers").MainView;
const ScreenOptions = @import("screen.zig").Options;

const SelectPanel = @import("Select.zig").Panel;
const RemovePanel = @import("Remove.zig").Panel;

const PanelTags = enum {
    Select,
    Remove,
    none,
};

pub const Panels = struct {
    allocator: std.mem.Allocator,
    Select: ?*SelectPanel,
    Remove: ?*RemovePanel,
    current_panel_tag: PanelTags,

    pub fn deinit(self: *Panels) void {
        if (self.Select) |member| {
            member.deinit();
        }
        if (self.Remove) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn frameCurrent(self: *Panels, allocator: std.mem.Allocator) !void {
        return switch (self.current_panel_tag) {
            .Select => self.Select.?.view.?.frame(allocator),
            .Remove => self.Remove.?.view.?.frame(allocator),
            .none => self.Select.?.view.?.frame(allocator),
        };
    }

    pub fn refresh(self: *Panels) void {
        switch (self.current_panel_tag) {
            .Select => self.Select.?.view.?.refresh(),
            .Remove => self.Remove.?.view.?.refresh(),
            .none => self.Select.?.view.?.refresh(),
        }
    }

    pub fn setCurrentToSelect(self: *Panels) void {
        self.current_panel_tag = PanelTags.Select;
    }

    pub fn setCurrentToRemove(self: *Panels) void {
        self.current_panel_tag = PanelTags.Remove;
    }

    pub fn setContainer(self: *Panels, container: *Container) !void {
        try self.Select.?.view.?.setContainer(container);
        try self.Remove.?.view.?.setContainer(container);
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

        return panels;
    }
};
