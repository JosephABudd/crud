const std = @import("std");
const dvui = @import("dvui");

const Event = dvui.Event;
const Options = dvui.Options;
const Rect = dvui.Rect;
const RectScale = dvui.RectScale;
const Size = dvui.Size;
const Widget = dvui.Widget;
const WidgetData = dvui.WidgetData;

pub const TabBarItemWidget = @This();

pub const Flow = enum {
    horizontal,
    vertical,
};

pub const InitOptions = struct {
    selected: ?bool = null,
    flow: ?Flow = null,
    id_extra: ?usize = null,
};

var horizontal_init_options: InitOptions = .{
    .selected = false,
    .flow = .horizontal,
};

var vertical_init_options: InitOptions = .{
    .selected = false,
    .flow = .vertical,
};

// Defaults.
// Defaults for tabs in a horizontal tabbar.
fn horizontalDefaultOptions() dvui.Options {
    var defaults: dvui.Options = .{
        .name = "HorizontalTabBarItem",
        .color_fill = .{ .name = .fill_hover },
        .corner_radius = .{ .x = 2, .y = 2, .w = 0, .h = 0 },
        .padding = .{ .x = 0, .y = 0, .w = 0, .h = 0 },
        .border = .{ .x = 1, .y = 1, .w = 1, .h = 0 },
        .margin = .{ .x = 4, .y = 0, .w = 0, .h = 8 },
        .expand = .none,
        .font_style = .body,
        // .debug = false,
    };
    const hover: dvui.Color = dvui.themeGet().color_fill_hover;
    const hover_hsl: dvui.Color.HSLuv = dvui.Color.HSLuv.fromColor(hover);
    const darken: dvui.Color = hover_hsl.lighten(-16).color();
    // const darken: dvui.Color = dvui.Color.darken(hover, 0.5);
    defaults.color_border = .{ .color = darken };
    return defaults;
}

fn horizontalDefaultSelectedOptions() dvui.Options {
    const bg: dvui.Color = dvui.themeGet().color_fill_window;
    var defaults = horizontalDefaultOptions();
    defaults.color_fill = .{ .color = bg };
    defaults.color_border = .{ .name = .accent };
    defaults.margin = .{ .x = 4, .y = 7, .w = 0, .h = 0 };

    return defaults;
}

fn verticalDefaultOptions() dvui.Options {
    var defaults: dvui.Options = .{
        .name = "VerticalTabBarItem",
        .color_fill = .{ .name = .fill_hover },
        .color_border = .{ .name = .fill_hover },
        .corner_radius = .{ .x = 2, .y = 0, .w = 0, .h = 2 },
        .padding = .{ .x = 0, .y = 0, .w = 1, .h = 0 },
        .border = .{ .x = 1, .y = 1, .w = 0, .h = 1 },
        .margin = .{ .x = 1, .y = 4, .w = 6, .h = 0 },
        .expand = .horizontal,
        .font_style = .body,
        .gravity_x = 1.0,
    };
    const hover: dvui.Color = dvui.themeGet().color_fill_hover;
    const hover_hsl: dvui.Color.HSLuv = dvui.Color.HSLuv.fromColor(hover);
    const darken: dvui.Color = hover_hsl.lighten(-16).color();
    // const darken: dvui.Color = dvui.Color.darken(hover, 0.5);
    defaults.color_border = .{ .color = darken };
    return defaults;
}

pub fn verticalContextOptions() dvui.Options {
    return .{
        .name = "VerticalContext",
        .corner_radius = .{ .x = 2, .y = 0, .w = 0, .h = 2 },
        .padding = .{ .x = 0, .y = 0, .w = 0, .h = 0 },
        .border = .{ .x = 0, .y = 0, .w = 0, .h = 0 },
        .margin = .{ .x = 0, .y = 0, .w = 0, .h = 0 },
        .expand = .horizontal,
        .gravity_x = 1.0,
        .background = false,
    };
}

fn verticalDefaultSelectedOptions() dvui.Options {
    const bg: dvui.Color = dvui.themeGet().color_fill_window;
    var defaults = verticalDefaultOptions();
    defaults.color_fill = .{ .color = bg };
    defaults.color_border = .{ .name = .accent };
    defaults.margin = .{ .x = 7, .y = 4, .w = 0, .h = 0 };
    return defaults;
}

pub fn verticalSelectedContextOptions() dvui.Options {
    return verticalContextOptions();
}

pub fn verticalTabBarItemLabel(src: std.builtin.SourceLocation, label_str: []const u8, init_opts: InitOptions) !?dvui.Rect {
    var vertical_init_opts: TabBarItemWidget.InitOptions = TabBarItemWidget.vertical_init_options;
    if (init_opts.id_extra) |id_extra| {
        vertical_init_opts.id_extra = id_extra;
    }
    if (init_opts.selected) |selected| {
        vertical_init_opts.selected = selected;
    }
    return tabBarItemLabel(src, label_str, vertical_init_opts);
}

pub fn horizontalTabBarItemLabel(src: std.builtin.SourceLocation, label_str: []const u8, init_opts: InitOptions) !?dvui.Rect {
    var horizontal_init_opts: TabBarItemWidget.InitOptions = TabBarItemWidget.horizontal_init_options;
    if (init_opts.id_extra) |id_extra| {
        horizontal_init_opts.id_extra = id_extra;
    }
    if (init_opts.selected) |selected| {
        horizontal_init_opts.selected = selected;
    }
    return tabBarItemLabel(src, label_str, horizontal_init_opts);
}

fn tabBarItemLabel(src: std.builtin.SourceLocation, label_str: []const u8, init_opts: TabBarItemWidget.InitOptions) !?dvui.Rect {
    var tbi = try tabBarItem(src, init_opts);
    var ret: ?dvui.Rect = null;
    if (tbi.activeRect()) |r| {
        ret = r;
    }

    var labelopts: dvui.Options = .{};
    if (tbi.show_active) {
        if (tbi.init_options.selected.?) {
            switch (tbi.init_options.flow.?) {
                .horizontal => {},
                .vertical => {
                    labelopts.gravity_x = 1;
                },
            }
        }
    }

    try dvui.labelNoFmt(@src(), label_str, labelopts);

    tbi.deinit();

    return ret;
}

pub fn tabBarItem(src: std.builtin.SourceLocation, init_opts: TabBarItemWidget.InitOptions) !*TabBarItemWidget {
    var ret = try dvui.currentWindow().arena.create(TabBarItemWidget);
    ret.* = TabBarItemWidget.init(src, init_opts);
    try ret.install(.{});
    return ret;
}

wd: WidgetData = undefined,
focused_last_frame: bool = undefined,
highlight: bool = false,
init_options: InitOptions = undefined,
activated: bool = false,
show_active: bool = false,
mouse_over: bool = false,

pub fn init(src: std.builtin.SourceLocation, init_opts: InitOptions) TabBarItemWidget {
    var self = TabBarItemWidget{};
    var defaults: dvui.Options = switch (init_opts.flow.?) {
        .horizontal => blk: {
            switch (init_opts.selected.?) {
                true => break :blk horizontalDefaultSelectedOptions(),
                false => break :blk horizontalDefaultOptions(), //horizontal_defaults,
            }
        },
        .vertical => blk: {
            switch (init_opts.selected.?) {
                true => break :blk verticalDefaultSelectedOptions(),
                false => break :blk verticalDefaultOptions(),
            }
        },
    };
    if (init_opts.id_extra) |id_extra| {
        defaults.id_extra = id_extra;
    }
    self.wd = dvui.WidgetData.init(src, .{}, defaults);
    self.init_options = init_opts;
    // self.show_active = init_opts.selected.?;
    self.focused_last_frame = dvui.dataGet(null, self.wd.id, "_focus_last", bool) orelse false;
    return self;
}

pub fn install(self: *TabBarItemWidget, opts: struct { process_events: bool = true, focus_as_outline: bool = false }) !void {
    try self.wd.register();

    if (self.wd.visible()) {
        try dvui.tabIndexSet(self.wd.id, self.wd.options.tab_index);
    }

    if (opts.process_events) {
        const evts = dvui.events();
        for (evts) |*e| {
            if (dvui.eventMatch(e, .{ .id = self.data().id, .r = self.data().borderRectScale().r })) {
                self.processEvent(e, false);
            }
        }
    }

    try self.wd.borderAndBackground(.{});

    if (self.show_active) {
        _ = dvui.parentSet(self.widget());
        return;
    }

    var focused: bool = false;
    if (self.wd.id == dvui.focusedWidgetId()) {
        focused = true;
    } else if (self.wd.id == dvui.focusedWidgetIdInCurrentSubwindow() and self.highlight) {
        focused = true;
    }
    if (focused) {
        if (self.mouse_over) {
            self.show_active = true;
            // try self.wd.focusBorder();
            _ = dvui.parentSet(self.widget());
            return;
        } else {
            focused = false;
            self.show_active = false;
            dvui.focusWidget(null, null, null);
        }
    }

    if ((self.wd.id == dvui.focusedWidgetIdInCurrentSubwindow()) or self.highlight) {
        const rs = self.wd.backgroundRectScale();
        try dvui.pathAddRect(rs.r, self.wd.options.corner_radiusGet().scale(rs.s));
        try dvui.pathFillConvex(self.wd.options.color(.fill_hover));
    } else if (self.wd.options.backgroundGet()) {
        const rs = self.wd.backgroundRectScale();
        try dvui.pathAddRect(rs.r, self.wd.options.corner_radiusGet().scale(rs.s));
        try dvui.pathFillConvex(self.wd.options.color(.fill));
    }
    _ = dvui.parentSet(self.widget());
}

pub fn activeRect(self: *const TabBarItemWidget) ?dvui.Rect {
    if (self.activated) {
        const rs = self.wd.backgroundRectScale();
        return rs.r.scale(1 / dvui.windowNaturalScale());
    } else {
        return null;
    }
}

pub fn widget(self: *TabBarItemWidget) dvui.Widget {
    return dvui.Widget.init(self, data, rectFor, screenRectScale, minSizeForChild, processEvent);
}

pub fn data(self: *TabBarItemWidget) *dvui.WidgetData {
    return &self.wd;
}

pub fn rectFor(self: *TabBarItemWidget, id: u32, min_size: dvui.Size, e: dvui.Options.Expand, g: dvui.Options.Gravity) dvui.Rect {
    return dvui.placeIn(self.wd.contentRect().justSize(), dvui.minSize(id, min_size), e, g);
}

pub fn screenRectScale(self: *TabBarItemWidget, rect: dvui.Rect) dvui.RectScale {
    return self.wd.contentRectScale().rectToRectScale(rect);
}

pub fn minSizeForChild(self: *TabBarItemWidget, s: dvui.Size) void {
    self.wd.minSizeMax(self.wd.padSize(s));
}

pub fn processEvent(self: *TabBarItemWidget, e: *dvui.Event, bubbling: bool) void {
    _ = bubbling;
    var focused: bool = false;
    var focused_id: u32 = 0;
    if (dvui.focusedWidgetIdInCurrentSubwindow()) |_focused_id| {
        focused = self.wd.id == _focused_id;
        focused_id = _focused_id;
    }
    switch (e.evt) {
        .mouse => |me| {
            switch (me.action) {
                .focus => {
                    e.handled = true;
                    // dvui.focusSubwindow(null, null); // focuses the window we are in
                    dvui.focusWidget(self.wd.id, null, e.num);
                },
                .press => {
                    if (me.button == dvui.enums.Button.left) {
                        e.handled = true;
                    }
                },
                .release => {
                    e.handled = true;
                    self.activated = true;
                    dvui.refresh(null, @src(), self.data().id);
                },
                .position => {
                    e.handled = true;
                    // We get a .position mouse event every frame.  If we
                    // focus the tabBar item under the mouse even if it's not
                    // moving then it breaks keyboard navigation.
                    if (dvui.mouseTotalMotion().nonZero()) {
                        // self.highlight = true;
                        self.mouse_over = true;
                    }
                },
                else => {},
            }
        },
        .key => |ke| {
            if (ke.code == .space and ke.action == .down) {
                e.handled = true;
                if (!self.activated) {
                    self.activated = true;
                    dvui.refresh(null, @src(), self.data().id);
                }
            } else if (ke.code == .right and ke.action == .down) {
                e.handled = true;
            }
        },
        else => {},
    }

    if (e.bubbleable()) {
        self.wd.parent.processEvent(e, true);
    }
}

pub fn deinit(self: *TabBarItemWidget) void {
    self.wd.minSizeSetAndRefresh();
    self.wd.minSizeReportToParent();
    _ = dvui.parentSet(self.wd.parent);
}