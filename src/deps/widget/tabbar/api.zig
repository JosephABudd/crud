const std = @import("std");
const dvui = @import("dvui");

const _framers_ = @import("framers");
const _startup_ = @import("startup");
const _tab_bar_widget_ = @import("TabBarWidget.zig");
const _tab_bar_item_widget_ = @import("TabBarItemWidget.zig").TabBarItemWidget;

const Container = @import("various").Container;
const Content = @import("various").Content;
const Direction = dvui.enums.Direction;
const MainView = @import("framers").MainView;

const MaxTabs: usize = 100;
const MaxLabelSize: usize = 255;

/// Tab is a container and implements Container.
/// Tab has content.
pub const Tab = struct {
    allocator: std.mem.Allocator,
    main_view: *MainView,
    movable: bool,
    closable: bool,
    id: usize,
    tabs: *Tabs,
    content: *Content,
    as_container: ?*Container,
    to_be_closed: bool,

    settings: Options,

    const Options = struct {
        movable: ?bool = null,
        closable: ?bool = null,
    };

    pub fn asContainer(self: *Tab) !*Container {
        return self.as_container.?.copy();
    }

    fn _asContainer(self: *Tab) !*Container {
        var close_fn: ?*const fn (implementor: *anyopaque) void = undefined;
        if (self.settings.closable.?) {
            close_fn = Tab.closeContainerFn;
        } else {
            close_fn = null;
        }
        return Container.init(
            self.allocator,
            self,
            close_fn,
            Tab.refreshContainerFn,
        );
    }

    // The returned Tab owns param content.
    // Param content is deinit if there is an error.
    pub fn init(
        tabs: *Tabs,
        main_view: *MainView,
        content: *Content,
        options: Options,
    ) !*Tab {
        var self = try tabs.allocator.create(Tab);
        self.allocator = tabs.allocator;
        self.main_view = main_view;
        self.tabs = tabs;
        self.content = content;
        // Settings.
        self.settings = Options{};
        // The tabs options for each tab can be overridden with the init options.
        if (options.closable) |closable| {
            self.settings.closable = closable;
        } else {
            self.settings.closable = tabs.settings.tabs_closable;
        }
        if (options.movable) |movable| {
            self.settings.movable = movable;
        } else {
            self.settings.movable = tabs.settings.tabs_movable;
        }
        self.to_be_closed = false;
        // As container.
        const self_as_container: *Container = try self._asContainer();
        errdefer {
            content.deinit();
            self.allocator.destroy(self);
        }
        try content.setContainer(self_as_container);
        errdefer self_as_container.deinit();
        return self;
    }

    pub fn label(self: *Tab, allocator: std.mem.Allocator) ![]const u8 {
        return self.content.label(allocator);
    }

    pub fn frame(self: *Tab, arena: std.mem.Allocator) !void {
        return self.content.frame(arena);
    }

    pub fn refresh(self: *Tab) void {
        // The tab's label may have been changed.
        // Force refresh.
        self.tabs.container.refresh();
    }

    pub fn deinit(self: *Tab) void {
        self.as_container.?.deinit();
        // Deinit the panel or screen.
        self.content.deinit();
        // Destory self.
        self.allocator.destroy(self);
    }

    pub fn close(self: *Tab) void {
        self.to_be_closed = true;
        // self.tabs.removeTab(self);
    }

    // Container functions.

    pub fn refreshContainerFn(implementor: *anyopaque) void {
        var self: *Tab = @alignCast(@ptrCast(implementor));
        self.refresh();
    }

    pub fn closeContainerFn(implementor: *anyopaque) void {
        var self: *Tab = @alignCast(@ptrCast(implementor));
        self.close();
    }
};

/// Tabs is never content.
/// A screen that uses Tabs is the content.
pub const Tabs = struct {
    allocator: std.mem.Allocator,
    lock: std.Thread.Mutex,
    main_view: *MainView,
    tabs: ?std.ArrayList(*Tab),
    selected_tab: ?*Tab,
    vertical_bar_is_visible: bool,
    container: *Container,

    settings: Options,

    pub const Options = struct {
        direction: ?dvui.enums.Direction = .horizontal,
        toggle_direction: ?bool = true,
        tabs_movable: ?bool = true,
        tabs_closable: ?bool = true,
        toggle_vertical_bar_visibility: ?bool = true,

        pub fn reset(
            original: Options,
            settings: Options,
        ) Options {
            var reset_options: Options = original;
            // Tab-bar direction.
            if (settings.direction) |value| {
                reset_options.direction = value;
            }
            // Allow the user to toggle the Tab-bar direction.
            if (settings.toggle_direction) |value| {
                reset_options.toggle_direction = value;
            }
            // Allow the user to move tabs.
            if (settings.tabs_movable) |value| {
                reset_options.tabs_movable = value;
            }
            // Allow the user to close tabs.
            if (settings.tabs_closable) |value| {
                reset_options.tabs_closable = value;
            }
            // Allow the user to toggle the visiblity of the vertical tab-bar.
            if (settings.toggle_vertical_bar_visibility) |value| {
                reset_options.toggle_vertical_bar_visibility = value;
            }
            return reset_options;
        }
    };

    // Used by the screen implementing this Tabs.
    // The main menu will exclude tab screens that will not frame.
    // So that there are no empty tab screens in the main menu.
    // Returns true if at least 1 tab will frame.
    pub fn willFrame(self: *Tabs) bool {
        self.lock.lock();
        defer self.lock.unlock();

        return self._willFrame();
    }

    /// lock must be on.
    pub fn _willFrame(self: *Tabs) bool {
        const tabs: []*Tab = self._slice() catch {
            return false;
        };
        for (tabs) |tab| {
            if (!tab.to_be_closed and tab.content.willFrame()) {
                // At least 1 tab will frame.
                return true;
            }
        }
        // No tabs will frame.
        return false;
    }

    pub fn setSelected(self: *Tabs, selected_tab: *Tab) void {
        self.lock.lock();
        defer self.lock.unlock();

        self.selected_tab = selected_tab;
    }

    // Used in the content panel's fn refresh.
    pub fn isSelected(self: *Tabs, tab: *Tab) bool {
        self.lock.lock();
        defer self.lock.unlock();

        return self.selected_tab == tab;
    }

    pub fn hasTab(self: *Tabs, tab_ptr: *anyopaque) !bool {
        self.lock.lock();
        defer self.lock.unlock();

        const tabs: []*Tab = try self._slice();
        const has_tab: *Tab = @alignCast(@ptrCast(tab_ptr));
        for (tabs) |tab| {
            if (tab == has_tab) {
                return true;
            }
        }
        return false;
    }

    pub fn appendTab(self: *Tabs, tab: *Tab, selected: bool) !void {
        self.lock.lock();
        defer self.lock.unlock();

        try self.tabs.?.append(tab);
        if (selected) {
            self.selected_tab = tab;
        }
    }

    pub fn removeTab(self: *Tabs, tab: *Tab) void {
        self.lock.lock();
        defer self.lock.unlock();

        tab.to_be_closed = true;
    }

    /// lock must be on.
    fn _removeTab(self: *Tabs, tab: *Tab) !void {
        const tabs: []*Tab = try self._slice();
        var previous_tab: ?*Tab = null;
        var following_tab: ?*Tab = null;
        const max_at: usize = tabs.len - 1;
        for (tabs, 0..) |tab_at, at| {
            if (at < max_at) {
                following_tab = tabs[at + 1];
            } else {
                following_tab = null;
            }
            if (tab_at == tab) {
                _ = self.tabs.?.orderedRemove(at);
                if (self.selected_tab) |selected_tab| {
                    if (selected_tab == tab_at) {
                        if (previous_tab != null) {
                            self.selected_tab = previous_tab;
                        } else {
                            self.selected_tab = following_tab;
                        }
                    }
                }
                // tab.deinit();
                return;
            } else {
                previous_tab = tab_at;
            }
        }
        // Not found;
        return error.TabNotFound;
    }

    fn slice(self: *Tabs) ![]*Tab {
        self.lock.lock();
        defer self.lock.unlock();

        return self._slice();
    }

    /// lock must be on.
    fn _slice(self: *Tabs) ![]*Tab {
        var clone = try self.tabs.?.clone();
        return clone.toOwnedSlice();
    }

    // Param container is owned by fn init even if there is an error.
    // Param container will be deleted if error along with it's real self.
    pub fn init(startup: _startup_.Frontend, container: *Container, init_options: Options) !*Tabs {
        var self: *Tabs = try startup.allocator.create(Tabs);
        self.container = container;
        self.selected_tab = null;
        self.tabs = null;
        self.lock = std.Thread.Mutex{};
        errdefer self.deinit();
        self.main_view = startup.main_view;
        self.allocator = startup.allocator;
        self.tabs = std.ArrayList(*Tab).init(startup.allocator);
        self.settings = Options.reset(Options{}, init_options);
        self.vertical_bar_is_visible = true;
        return self;
    }

    pub fn deinit(self: *Tabs) void {
        defer self.allocator.destroy(self);

        self.container.deinit();

        if (self.tabs != null) {
            const tabs = self.tabs.?.toOwnedSlice() catch {
                return;
            };
            for (tabs) |tab| {
                tab.deinit();
            }
            self.allocator.free(tabs);
        }
    }

    fn moveTab(self: *Tabs, to: usize, from: usize) !void {
        const tab: *Tab = self.tabs.?.orderedRemove(from);
        try self.tabs.?.insert(to, @constCast(tab));
    }

    pub fn frame(self: *Tabs, arena: std.mem.Allocator) !void {
        self.lock.lock();
        defer self.lock.unlock();

        const tabs: []*Tab = try self._slice();
        for (tabs) |tab| {
            if (tab.to_be_closed) {
                try self._removeTab(tab);
            }
        }

        return switch (self.settings.direction.?) {
            .horizontal => self._frameHorizontalTabBar(arena),
            .vertical => self._frameVerticalTabBar(arena),
        };
    }

    /// lock must be on.
    fn _frameVerticalTabBar(self: *Tabs, arena: std.mem.Allocator) !void {
        var layout = try dvui.box(@src(), .horizontal, .{ .expand = .both });
        defer layout.deinit();

        {
            // The vertical column.
            var column = try _tab_bar_widget_.verticalTabBarColumn(@src());
            defer column.deinit();

            if (self.settings.toggle_vertical_bar_visibility.? or self.vertical_bar_is_visible) {
                // User can hide/show the tab-bar.
                // User can toggle the direction.

                if (self.settings.toggle_direction.?) {
                    // horizontal row of 2 icons above the tab-bar.
                    var direction: dvui.enums.Direction = undefined;
                    if (self.vertical_bar_is_visible) {
                        direction = .horizontal;
                    } else {
                        direction = .vertical;
                    }
                    const icons = try dvui.box(@src(), direction, .{ .gravity_x = 0.5, .gravity_y = 0.0 });
                    defer icons.deinit();

                    if (self.settings.toggle_vertical_bar_visibility.?) {
                        // Hide show tab-bar button.
                        if (self.vertical_bar_is_visible) {
                            // Icon to hide the tab-bar.
                            if (try dvui.buttonIcon(@src(), "hide_horizontal", dvui.entypo.eye_with_line, .{}, .{})) {
                                self.vertical_bar_is_visible = false;
                            }
                        } else {
                            // Icon to show the tab-bar.
                            if (try dvui.buttonIcon(@src(), "show_horizontal", dvui.entypo.eye, .{}, .{})) {
                                self.vertical_bar_is_visible = true;
                            }
                        }
                    }

                    // Switch to horizontal tab-bar button.
                    if (try dvui.buttonIcon(@src(), "horizontal_switch", dvui.entypo.align_top, .{}, .{ .gravity_x = 0.5, .gravity_y = 0.0 })) {
                        self.settings.direction.? = .horizontal;
                    }
                } else {
                    // User can't toggle direction.
                    // Icon to show the tab-bar.
                    if (self.settings.toggle_vertical_bar_visibility.?) {
                        // Hide show tab-bar button.
                        if (self.vertical_bar_is_visible) {
                            // Icon to hide the tab-bar.
                            if (try dvui.buttonIcon(@src(), "hide_horizontal", dvui.entypo.eye_with_line, .{}, .{})) {
                                self.vertical_bar_is_visible = false;
                            }
                        } else {
                            // Icon to show the tab-bar.
                            if (try dvui.buttonIcon(@src(), "show_horizontal", dvui.entypo.eye, .{}, .{})) {
                                self.vertical_bar_is_visible = true;
                            }
                        }
                    }
                }

                if (self.vertical_bar_is_visible) {
                    // Show the vertical tab-bar.
                    // // The vertical scroller.
                    var scroller = try _tab_bar_widget_.verticalTabScroller(@src());
                    defer scroller.deinit();

                    // // The tab bar.
                    var tabbar = try _tab_bar_widget_.verticalTabBar(@src());
                    defer tabbar.deinit();

                    const tabs: []*Tab = try self._slice();
                    const last: usize = tabs.len - 1;
                    var had_context: bool = false;
                    var previous_tab: ?*Tab = null;
                    for (tabs, 0..) |tab, i| {
                        if (!tab.content.willFrame()) {
                            // This tab will not frame.
                            if (self.selected_tab == tab) {
                                self.selected_tab = previous_tab;
                            }
                            continue;
                        }
                        defer previous_tab = tab;
                        if (self.selected_tab == null) {
                            self.selected_tab = tab;
                        }
                        const selected: bool = self.selected_tab == tab;
                        // The context area around the menu item.
                        var context_options: dvui.Options = undefined;
                        if (selected) {
                            context_options = _tab_bar_item_widget_.verticalSelectedContextOptions();
                        } else {
                            context_options = _tab_bar_item_widget_.verticalContextOptions();
                        }
                        context_options.id_extra = i;
                        const context = try dvui.context(@src(), context_options);
                        defer context.deinit();

                        if (context.activePoint()) |cp| {
                            had_context = true;
                            if (had_context and (tab.settings.movable.? or tab.settings.closable.?)) {
                                const tab_label: []const u8 = try tab.label(arena);
                                defer arena.free(tab_label);
                                var context_menu = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(cp), .{ .id_extra = i });
                                defer context_menu.deinit();

                                if (tab.settings.movable.?) {
                                    if (i > 0) {
                                        // Go left label.
                                        if (try dvui.menuItemLabel(@src(), "Move Tab Above", .{ .submenu = true }, .{ .expand = .horizontal })) |r| {
                                            var move_left = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(dvui.Point{ .x = r.x, .y = r.y + r.h }), .{});
                                            defer move_left.deinit();
                                            var j: usize = i - 1;
                                            while (j >= 0) : (j -= 1) {
                                                const left_tab: *Tab = tabs[j];
                                                const left_tab_label: []const u8 = try left_tab.label(arena);
                                                defer arena.free(left_tab_label);
                                                if ((try dvui.menuItemLabel(@src(), left_tab_label, .{ .submenu = false }, .{ .expand = .vertical, .id_extra = j })) != null) {
                                                    try self.moveTab(j, i);
                                                    dvui.menuGet().?.close();
                                                }

                                                if (j == 0) {
                                                    break;
                                                }
                                            }
                                        }
                                    }

                                    if (i < last) {
                                        // Go right label.
                                        if (try dvui.menuItemLabel(@src(), "Move Tab Below", .{ .submenu = true }, .{ .expand = .horizontal })) |r| {
                                            var move_right = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(dvui.Point{ .x = r.x, .y = r.y + r.h }), .{});
                                            defer move_right.deinit();
                                            var j: usize = i + 1;
                                            while (j <= last) : (j += 1) {
                                                const right_tab: *Tab = tabs[j];
                                                const right_tab_label: []const u8 = try right_tab.label(arena);
                                                defer arena.free(right_tab_label);
                                                if ((try dvui.menuItemLabel(@src(), right_tab_label, .{ .submenu = false }, .{ .expand = .vertical, .id_extra = j })) != null) {
                                                    try self.moveTab(j, i);
                                                    dvui.menuGet().?.close();
                                                }
                                            }
                                        }
                                    }
                                }

                                if (try dvui.menuItemIcon(@src(), "close", dvui.entypo.align_top, .{ .submenu = false }, .{ .expand = .vertical }) != null) {
                                    dvui.menuGet().?.close();
                                    return;
                                }

                                if (tab.settings.closable.?) {
                                    // Close tab.
                                    const close_label: []const u8 = try std.fmt.allocPrint(self.allocator, "Close this {s} tab.", .{tab_label});
                                    if ((try dvui.menuItemLabel(@src(), close_label, .{ .submenu = false }, .{ .expand = .vertical, .color_text = .{ .color = dvui.Color{ .r = 0xff, .g = 0x00, .b = 0x00 } } })) != null) {
                                        tab.close();
                                        dvui.menuGet().?.close();
                                    }
                                }
                            }
                        }

                        {
                            const tab_label: []const u8 = try tab.label(arena);
                            defer arena.free(tab_label);
                            if (try _tab_bar_item_widget_.verticalTabBarItemLabel(@src(), tab_label, .{ .selected = selected, .id_extra = i })) |_| {
                                if (had_context) {
                                    // Right mouse button click.
                                    return;
                                }
                                // Left mouse click.
                                // The user selected this tab.
                                if (!selected) {
                                    self.selected_tab = tab;
                                }
                            }
                        }
                    }
                }
            } else {
                // User can hide/show the tab-bar.
                // User can toggle the direction.
                // Vertical tab-bar is hidden.

                // // vertical column of 2 icons above empty space.
                // const icon_column = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.0 });
                // defer icon_column.deinit();

                // // Hide show tab-bar button.
                // // Icon to show the tab-bar.
                // if (try dvui.buttonIcon(@src(), "show_horizontal", dvui.entypo.eye, .{}, .{})) {
                //     self.vertical_bar_is_visible = true;
                // }

                // Switch to horizontal tab-bar button.
                if (try dvui.buttonIcon(@src(), "horizontal_switch", dvui.entypo.align_top, .{}, .{ .gravity_x = 0.5, .gravity_y = 0.0 })) {
                    self.settings.direction.? = .horizontal;
                }
            }
        }

        // The content area for a tab's content.
        // Display the selected tab's content.

        // KICKZIG TODO:
        // Display your selected tab's content if there is a selected tab.
        try self._frameSelectedTab(arena);
    }

    /// lock must be on.
    fn _frameHorizontalTabBar(self: *Tabs, arena: std.mem.Allocator) !void {
        var layout = try dvui.box(@src(), .vertical, .{ .expand = .both });
        defer layout.deinit();

        {
            // The horizontal row.
            var row = try _tab_bar_widget_.horizontalTabBarRow(@src());
            defer row.deinit();

            if (self.settings.toggle_direction.?) {
                if (try dvui.buttonIcon(@src(), "vertical_switch", dvui.entypo.align_left, .{}, .{ .gravity_x = 0.0, .gravity_y = 0.5 })) {
                    self.settings.direction.? = .vertical;
                }
            }

            // // The horizontal scroller.
            var scroller = try _tab_bar_widget_.horizontalTabScroller(@src());
            defer scroller.deinit();

            // // The tab bar.
            var tabbar = try _tab_bar_widget_.horizontalTabBar(@src());
            defer tabbar.deinit();

            const tabs: []*Tab = try self._slice();
            const last: usize = tabs.len - 1;
            var had_context: bool = false;
            var previous_tab: ?*Tab = null;
            for (tabs, 0..) |tab, i| {
                if (!tab.content.willFrame()) {
                    // This tab will not frame.
                    if (self.selected_tab == tab) {
                        self.selected_tab = previous_tab;
                    }
                    continue;
                }
                defer previous_tab = tab;
                if (self.selected_tab == null) {
                    self.selected_tab = tab;
                }
                const selected: bool = self.selected_tab == tab;
                const context = try dvui.context(@src(), .{ .id_extra = i });
                defer context.deinit();

                if (context.activePoint()) |cp| {
                    had_context = true;
                    if (tab.settings.movable.? or tab.settings.closable.?) {
                        var context_menu = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(cp), .{ .id_extra = i });
                        defer context_menu.deinit();

                        if (tab.settings.movable.?) {
                            if (i > 0) {
                                // Go left label.
                                if (try dvui.menuItemLabel(@src(), "Move Left Of", .{ .submenu = true }, .{ .expand = .horizontal })) |r| {
                                    var move_left = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(dvui.Point{ .x = r.x, .y = r.y + r.h }), .{});
                                    defer move_left.deinit();
                                    var j: usize = i - 1;
                                    while (j >= 0) : (j -= 1) {
                                        const left_tab: *Tab = tabs[j];
                                        const left_tab_label: []const u8 = try left_tab.label(arena);
                                        defer arena.free(left_tab_label);
                                        if ((try dvui.menuItemLabel(@src(), left_tab_label, .{ .submenu = false }, .{ .expand = .vertical, .id_extra = j })) != null) {
                                            try self.moveTab(j, i);
                                            dvui.menuGet().?.close();
                                        }

                                        if (j == 0) {
                                            break;
                                        }
                                    }
                                }
                            }

                            if (i < last) {
                                // Go right label.
                                if (try dvui.menuItemLabel(@src(), "Move Right Of", .{ .submenu = true }, .{ .expand = .horizontal })) |r| {
                                    var move_right = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(dvui.Point{ .x = r.x, .y = r.y + r.h }), .{});
                                    defer move_right.deinit();
                                    var j: usize = i + 1;
                                    while (j <= last) : (j += 1) {
                                        const right_tab: *Tab = tabs[j];
                                        const right_tab_label: []const u8 = try right_tab.label(arena);
                                        defer arena.free(right_tab_label);
                                        if ((try dvui.menuItemLabel(@src(), right_tab_label, .{ .submenu = false }, .{ .expand = .vertical, .id_extra = j })) != null) {
                                            try self.moveTab(j, i);
                                            dvui.menuGet().?.close();
                                        }
                                    }
                                }
                            }
                        }

                        if (try dvui.menuItemIcon(@src(), "close", dvui.entypo.align_top, .{ .submenu = false }, .{ .expand = .horizontal }) != null) {
                            dvui.menuGet().?.close();
                            return;
                        }

                        if (tab.settings.closable.?) {
                            // Close tab.
                            const tab_label: []const u8 = try tab.label(arena);
                            defer arena.free(tab_label);
                            const close_label: []const u8 = try std.fmt.allocPrint(self.allocator, "Close this {s} tab.", .{tab_label});
                            if ((try dvui.menuItemLabel(@src(), close_label, .{ .submenu = false }, .{ .expand = .horizontal, .color_text = .{ .color = dvui.Color{ .r = 0xff, .g = 0x00, .b = 0x00 } } })) != null) {
                                tab.close();
                                dvui.menuGet().?.close();
                            }
                        }
                    }
                }

                {
                    // const tab_label: []const u8 = try tab.labelFn(tab.implementor);
                    const tab_label: []const u8 = try tab.label(arena);
                    defer arena.free(tab_label);
                    if (try _tab_bar_item_widget_.horizontalTabBarItemLabel(@src(), tab_label, .{ .selected = selected, .id_extra = i })) |_| {
                        if (had_context) {
                            // Right mouse button click.
                            return;
                        }
                        // Left mouse click.
                        // The user selected this tab.
                        if (!selected) {
                            self.selected_tab = tab;
                        }
                    }
                }
            }
        }

        // The content area for a tab's content.
        // Display the selected tab's content.

        // KICKZIG TODO:
        // Display your selected tab's content if there is a selected tab.
        try self._frameSelectedTab(arena);
    }

    /// lock must be on.
    fn _frameSelectedTab(self: *Tabs, arena: std.mem.Allocator) !void {
        if (self.selected_tab) |selected_tab| {
            try selected_tab.frame(arena);
        }
    }
};