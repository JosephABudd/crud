const std = @import("std");
const dvui = @import("dvui");

const _framers_ = @import("framers");
const _lock_ = @import("lock");
const _startup_ = @import("startup");
const _various_ = @import("various");
const Direction = dvui.enums.Direction;
const MainView = @import("framers").MainView;
const _TabBarWidget_ = @import("TabBarWidget.zig");
const _TabBarItemWidget_ = @import("TabBarItemWidget.zig").TabBarItemWidget;
const ScreenTags = @import("framers").ScreenTags;

const MaxTabs: usize = 100;
const MaxLabelSize: usize = 255;

pub const Tab = struct {
    allocator: std.mem.Allocator,
    main_view: *MainView,
    movable: bool,
    closable: bool,
    id: usize,
    tabs: *Tabs,
    implementor: *anyopaque,
    labelFn: *const fn (implementor: *anyopaque) anyerror![]const u8,
    frameFn: *const fn (implementor: *anyopaque, arena: std.mem.Allocator) anyerror!void,
    setStateFn: ?*const fn (implementor: *anyopaque, state: *anyopaque) anyerror!void,
    refreshFn: *const fn (implementor: *anyopaque) void,
    deinitFn: *const fn (implementor: *anyopaque) void,
    container_screen_tag: ScreenTags,
    panel_tag_as_int: usize, // Used for panel tabs only.

    const Options = struct {
        movable: ?bool = null,
        closable: ?bool = null,
    };

    pub fn asContainer(self: *Tab) !*_various_.Container {
        return _various_.Container.init(
            self.allocator,
            self,
            Tab.containerRefreshFn,
            Tab.containerCloseFn,
        );
    }

    pub fn initPanelTab(
        tabs: *Tabs,
        main_view: *MainView,
        implementor: *anyopaque,
        labelFn: *const fn (implementor: *anyopaque) anyerror![]const u8,
        setStateFn: *const fn (implementor: *anyopaque, state: *anyopaque) anyerror!void,
        frameFn: *const fn (implementor: *anyopaque, arena: std.mem.Allocator) anyerror!void,
        refreshFn: *const fn (implementor: *anyopaque) void,
        deinitFn: *const fn (implementor: *anyopaque) void,
        panel_tag_as_int: usize,
        container_screen_tag: ScreenTags,
        options: Options,
    ) !*Tab {
        var self = try tabs.allocator.create(Tab);
        self.allocator = tabs.allocator;
        self.main_view = main_view;
        self.tabs = tabs;
        self.implementor = implementor;
        self.labelFn = labelFn;
        self.setStateFn = setStateFn;
        self.frameFn = frameFn;
        self.refreshFn = refreshFn;
        self.deinitFn = deinitFn;
        self.container_screen_tag = container_screen_tag;
        self.panel_tag_as_int = panel_tag_as_int; // Used for panel tabs only.
        // The tabs options for each tab can be overridden with the init options.
        if (options.closable) |closable| {
            self.closable = closable;
        } else {
            self.closable = tabs.tabs_closable;
        }
        if (options.movable) |movable| {
            self.movable = movable;
        } else {
            self.movable = tabs.tabs_movable;
        }
        return self;
    }

    pub fn initScreenTab(
        tabs: *Tabs,
        main_view: *MainView,
        implementor: *anyopaque,
        labelFn: *const fn (implementor: *anyopaque) anyerror![]const u8,
        frameFn: *const fn (implementor: *anyopaque, arena: std.mem.Allocator) anyerror!void,
        refreshFn: *const fn (implementor: *anyopaque) void,
        deinitFn: *const fn (implementor: *anyopaque) void,
        container_screen_tag: ScreenTags,
        options: Options,
    ) !*Tab {
        var self = try tabs.allocator.create(Tab);
        self.allocator = tabs.allocator;
        self.main_view = main_view;
        self.tabs = tabs;
        self.implementor = implementor;
        self.labelFn = labelFn;
        self.setStateFn = null;
        self.frameFn = frameFn;
        self.refreshFn = refreshFn;
        self.deinitFn = deinitFn;
        self.container_screen_tag = container_screen_tag;
        self.panel_tag_as_int = 0; // Not used for screens.
        // The tabs options for each tab can be overridden with the init options.
        if (options.closable) |closable| {
            self.closable = closable;
        } else {
            self.closable = tabs.tabs_closable;
        }
        if (options.movable) |movable| {
            self.movable = movable;
        } else {
            self.movable = tabs.tabs_movable;
        }
        return self;
    }

    pub fn setState(self: *Tab, state: *anyopaque) !void {
        if (self.setStateFn) |setStateFn| {
            return setStateFn(self.implementor, state);
        }
        return error.NoSetStateFn;
    }

    // The tab screen's messenger updates the screen's own panels.
    // So the tab screen's messenger needs this.
    pub fn panelTabAsInt(self: *Tab) usize {
        return self.panel_tag_as_int;
    }

    pub fn label(self: *const Tab) ![]const u8 {
        return self.labelFn(self.implementor);
    }

    pub fn frame(self: *Tab, arena: std.mem.Allocator) ![]const u8 {
        return self.frameFn(self.implementor, arena);
    }

    pub fn refresh(self: *Tab) void {
        return self.refreshFn(self.implementor);
    }

    pub fn deinit(self: *const Tab) void {
        // Deinit the panel or screen.
        self.deinitFn(self.implementor);
        // Destory self.
        self.allocator.destroy(self);
    }

    pub fn close(self: *const Tab) void {
        self.tabs.removeTab(self);
    }

    // Container functions.

    pub fn containerRefreshFn(implementor: *anyopaque) void {
        var self: *Tab = @alignCast(@ptrCast(implementor));
        self.main_view.refresh(self.container_screen_tag);
    }

    pub fn containerCloseFn(implementor: *anyopaque) void {
        var self: *Tab = @alignCast(@ptrCast(implementor));
        self.close();
    }
};

pub const Tabs = struct {
    allocator: std.mem.Allocator,
    lock: *_lock_.ThreadLock,
    main_view: *MainView,
    direction: Direction,
    tabs_movable: bool,
    tabs_closable: bool,
    toggle_direction: bool,
    tabs: std.ArrayList(*Tab),
    selected_tab: ?*const Tab,
    to_be_removed: ?*const Tab,

    const Options = struct {
        direction: ?Direction = null,
        toggle_direction: ?bool = null,
        tabs_movable: ?bool = null,
        tabs_closable: ?bool = null,
    };

    // Used by the screen implementing this Tabs.
    // The main menu will exclude tab screens that will not frame.
    // So that there are no empty tab screens in the main menu.
    // If a tab screen has 1 or more tabs then it is included in the main menu.
    pub fn will_frame(self: *Tabs) bool {
        self.lock.lock();
        defer self.lock.unlock();

        return switch (self.tabs.items.len) {
            0 => false,
            else => true,
        };
    }

    pub fn setSelected(self: *Tabs, selected_tab: *Tab) void {
        self.lock.lock();
        defer self.lock.unlock();

        self.selected_tab = selected_tab;
    }

    // Used in the content panel's fn refresh.
    pub fn isSelected(self: *Tabs, tab: *const Tab) bool {
        self.lock.lock();
        defer self.lock.unlock();

        return self.selected_tab == tab;
    }

    pub fn hasTab(self: *Tabs, tab_ptr: *anyopaque) bool {
        const has_tab: *Tab = @alignCast(@ptrCast(tab_ptr));
        const tabs: []const *Tab = self.slice();
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

        try self.tabs.append(tab);
        if (selected) {
            self.setSelected(tab);
        }
    }

    pub fn removeTab(self: *Tabs, tab: *const Tab) void {
        self.to_be_removed = tab;
    }

    fn _removeTab(self: *Tabs, tab: *const Tab) !void {
        self.lock.lock();
        defer self.lock.unlock();

        const tabs: []*const Tab = try self.slice();
        var previous_tab: ?*const Tab = null;
        var following_tab: ?*const Tab = null;
        const max_at: usize = tabs.len - 1;
        for (tabs, 0..) |tab_at, at| {
            if (at < max_at) {
                following_tab = tabs[at + 1];
            } else {
                following_tab = null;
            }
            if (tab_at == tab) {
                _ = self.tabs.orderedRemove(at);
                if (self.selected_tab) |selected_tab| {
                    if (selected_tab == tab_at) {
                        if (previous_tab != null) {
                            self.selected_tab = previous_tab;
                        } else {
                            self.selected_tab = following_tab;
                        }
                    }
                }
                tab.deinit();
                return;
            } else {
                previous_tab = tab_at;
            }
        }
        // Not found;
        return error.TabNotFound;
    }

    fn slice(self: *Tabs) ![]*const Tab {
        self.lock.lock();
        defer self.lock.unlock();

        var clone = try self.tabs.clone();
        return clone.toOwnedSlice();
    }

    pub fn init(startup: _startup_.Frontend, options: Options) !*Tabs {
        var self: *Tabs = try startup.allocator.create(Tabs);
        self.to_be_removed = null;
        self.selected_tab = null;
        self.lock = try _lock_.init(startup.allocator);
        errdefer startup.allocator.destroy(self);
        self.main_view = startup.main_view;
        self.allocator = startup.allocator;
        self.tabs = std.ArrayList(*Tab).init(startup.allocator);
        // Options.
        if (options.direction) |direction| {
            self.direction = direction;
        } else {
            self.direction = .horizontal;
        }
        if (options.toggle_direction) |toggle_direction| {
            self.toggle_direction = toggle_direction;
        } else {
            self.toggle_direction = false;
        }
        if (options.tabs_movable) |tabs_movable| {
            self.tabs_movable = tabs_movable;
        } else {
            self.tabs_movable = false;
        }
        if (options.tabs_closable) |tabs_closable| {
            self.tabs_closable = tabs_closable;
        } else {
            self.tabs_closable = false;
        }
        return self;
    }

    pub fn deinit(self: *Tabs) void {
        self.lock.deinit();
        defer self.allocator.destroy(self);

        const tabs = self.tabs.toOwnedSlice() catch {
            return;
        };
        for (tabs) |tab| {
            tab.deinit();
        }
    }

    pub fn moveTab(self: *Tabs, to: usize, from: usize) !void {
        self.lock.lock();
        defer self.lock.unlock();

        const tab: *const Tab = self.tabs.orderedRemove(from);
        try self.tabs.insert(to, @constCast(tab));
    }

    pub fn frame(self: *Tabs, arena: std.mem.Allocator) !void {
        return switch (self.direction) {
            .horizontal => self.frameHorizontalTabBar(arena),
            .vertical => self.frameVerticalTabBar(arena),
        };
    }

    fn frameVerticalTabBar(self: *Tabs, arena: std.mem.Allocator) !void {
        var layout = try dvui.box(@src(), .horizontal, .{ .expand = .both });
        defer layout.deinit();

        {
            // The vertical column.
            var column = try _TabBarWidget_.verticalTabBarColumn(@src());
            defer column.deinit();

            if (self.toggle_direction) {
                if (try dvui.buttonIcon(@src(), "horizontal_switch", dvui.entypo.align_top, .{}, .{ .gravity_x = 0.5, .gravity_y = 0.0 })) {
                    self.direction = .horizontal;
                }
            }

            // // The vertical scroller.
            var scroller = try _TabBarWidget_.verticalTabScroller(@src());
            defer scroller.deinit();

            // // The tab bar.
            var tabbar = try _TabBarWidget_.verticalTabBar(@src());
            defer tabbar.deinit();

            const tabs: []*const Tab = try self.slice();
            const last: usize = tabs.len - 1;
            var had_context: bool = false;
            for (tabs, 0..) |tab, i| {
                const selected: bool = self.selected_tab == tab;
                // The context area around the menu item.
                var context_options: dvui.Options = undefined;
                if (selected) {
                    context_options = _TabBarItemWidget_.verticalSelectedContextOptions();
                } else {
                    context_options = _TabBarItemWidget_.verticalContextOptions();
                }
                context_options.id_extra = i;
                const context = try dvui.context(@src(), context_options);
                defer context.deinit();

                if (context.activePoint()) |cp| {
                    had_context = true;
                    if (had_context and (tab.movable or tab.closable)) {
                        const tab_label: []const u8 = try tab.label();
                        var context_menu = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(cp), .{ .id_extra = i });
                        defer context_menu.deinit();

                        if (tab.movable) {
                            if (i > 0) {
                                // Go left label.
                                if (try dvui.menuItemLabel(@src(), "Move Tab Above", .{ .submenu = true }, .{ .expand = .horizontal })) |r| {
                                    var move_left = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(dvui.Point{ .x = r.x, .y = r.y + r.h }), .{});
                                    defer move_left.deinit();
                                    var j: usize = i - 1;
                                    while (j >= 0) : (j -= 1) {
                                        const left_tab: *const Tab = tabs[j];
                                        const left_tab_label: []const u8 = try left_tab.label();
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
                                        const right_tab: *const Tab = tabs[j];
                                        const right_tab_label: []const u8 = try right_tab.label();
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

                        if (tab.closable) {
                            // Close tab.
                            const close_label: []const u8 = try std.fmt.allocPrint(self.allocator, "Close this {s} tab.", .{tab_label});
                            if ((try dvui.menuItemLabel(@src(), close_label, .{ .submenu = false }, .{ .expand = .vertical, .color_text = .{ .color = dvui.Color{ .r = 0xff, .g = 0x00, .b = 0x00 } } })) != null) {
                                tab.close();
                                dvui.menuGet().?.close();
                            }
                        }
                    }
                }

                const tab_label: []const u8 = try tab.labelFn(tab.implementor);
                if (try _TabBarItemWidget_.verticalTabBarItemLabel(@src(), tab_label, .{ .selected = selected, .id_extra = i })) |_| {
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

        // The content area for a tab's content.
        // Display the selected tab's content.

        // KICKZIG TODO:
        // Display your selected tab's content if there is a selected tab.
        try self.frameSelectedTab(arena);

        // If there is a tab to be removed then remove it.
        if (self.to_be_removed) |to_be_removed| {
            self.to_be_removed = null;
            try self._removeTab(to_be_removed);
        }
    }

    fn frameHorizontalTabBar(self: *Tabs, arena: std.mem.Allocator) !void {
        var layout = try dvui.box(@src(), .vertical, .{ .expand = .both });
        defer layout.deinit();

        {
            // The horizontal row.
            var row = try _TabBarWidget_.horizontalTabBarRow(@src());
            defer row.deinit();

            if (self.toggle_direction) {
                if (try dvui.buttonIcon(@src(), "vertical_switch", dvui.entypo.align_left, .{}, .{ .gravity_x = 0.0, .gravity_y = 0.5 })) {
                    self.direction = .vertical;
                }
            }

            // // The horizontal scroller.
            var scroller = try _TabBarWidget_.horizontalTabScroller(@src());
            defer scroller.deinit();

            // // The tab bar.
            var tabbar = try _TabBarWidget_.horizontalTabBar(@src());
            defer tabbar.deinit();

            const tabs: []*const Tab = try self.slice();
            const last: usize = tabs.len - 1;
            var had_context: bool = false;
            for (tabs, 0..) |tab, i| {
                const context = try dvui.context(@src(), .{ .id_extra = i });
                defer context.deinit();

                if (context.activePoint()) |cp| {
                    had_context = true;
                    if (tab.movable or tab.closable) {
                        var context_menu = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(cp), .{ .id_extra = i });
                        defer context_menu.deinit();

                        if (tab.movable) {
                            if (i > 0) {
                                // Go left label.
                                if (try dvui.menuItemLabel(@src(), "Move Left Of", .{ .submenu = true }, .{ .expand = .horizontal })) |r| {
                                    var move_left = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(dvui.Point{ .x = r.x, .y = r.y + r.h }), .{});
                                    defer move_left.deinit();
                                    var j: usize = i - 1;
                                    while (j >= 0) : (j -= 1) {
                                        const left_tab: *const Tab = tabs[j];
                                        const left_tab_label: []const u8 = try left_tab.label();
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
                                        const right_tab: *const Tab = tabs[j];
                                        const right_tab_label: []const u8 = try right_tab.label();
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

                        if (tab.closable) {
                            // Close tab.
                            const tab_label: []const u8 = try tab.label();
                            const close_label: []const u8 = try std.fmt.allocPrint(self.allocator, "Close this {s} tab.", .{tab_label});
                            if ((try dvui.menuItemLabel(@src(), close_label, .{ .submenu = false }, .{ .expand = .horizontal, .color_text = .{ .color = dvui.Color{ .r = 0xff, .g = 0x00, .b = 0x00 } } })) != null) {
                                tab.close();
                                dvui.menuGet().?.close();
                            }
                        }
                    }
                }

                const selected: bool = self.selected_tab == tab;
                const tab_label: []const u8 = try tab.labelFn(tab.implementor);
                if (try _TabBarItemWidget_.horizontalTabBarItemLabel(@src(), tab_label, .{ .selected = selected, .id_extra = i })) |_| {
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

        // The content area for a tab's content.
        // Display the selected tab's content.

        // KICKZIG TODO:
        // Display your selected tab's content if there is a selected tab.
        try self.frameSelectedTab(arena);

        // If there is a tab to be removed then remove it.
        if (self.to_be_removed) |to_be_removed| {
            self.to_be_removed = null;
            try self._removeTab(to_be_removed);
        }
    }

    fn frameSelectedTab(self: *Tabs, arena: std.mem.Allocator) !void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.selected_tab) |selected_tab| {
            try selected_tab.frameFn(selected_tab.implementor, arena);
        }
    }
};