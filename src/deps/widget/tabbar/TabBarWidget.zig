const std = @import("std");
const dvui = @import("dvui");

const Direction = dvui.enums.Direction;
const Event = dvui.Event;
const Options = dvui.Options;
const Point = dvui.Point;
const Rect = dvui.Rect;
const RectScale = dvui.RectScale;
const Size = dvui.Size;
const Widget = dvui.Widget;
const WidgetData = dvui.WidgetData;
const BoxWidget = dvui.BoxWidget;

pub const TabBarWidget = @This();
const background_color: dvui.Options.ColorsFromTheme = .fill_control;

pub var horizontalDefaults: Options = .{
    .name = "HorizontalTabBar",
    .background = true,
    .color_fill = .{ .name = background_color },
    .expand = .horizontal,
};
pub var verticalDefaults: Options = .{
    .name = "VerticalTabBar",
    .background = true,
    .color_fill = .{ .name = background_color },
    .expand = .both,
};

pub const InitOptions = struct {
    dir: Direction = undefined,
    submenus_activated_by_default: bool = false,
};

wd: WidgetData = undefined,
dir: Direction = undefined,
winId: u32 = undefined,
box: BoxWidget = undefined,

// whether submenus in a child menu should default to open (for mouse interactions, not for keyboard)
// submenus_in_child: bool = false,
mouse_over: bool = false,

// The contentArea is where the selected tab's content is displayed.
// The contentArea lies right of the verticalTabBarColumn.
// The contentArea lies below the horizontalTabBarRow.
// The caller owns the returned value.
pub fn contentArea(src: std.builtin.SourceLocation) !*dvui.BoxWidget {
    return try dvui.box(src, .vertical, .{ .expand = .both, .background = true });
}

// Tab bar row and column.

// A horizontalTabBarRow contains is the horizontal tab-bar.
// The horizontalTabBarRow lies above the tab-content area.
// The caller owns the returned value.
pub fn horizontalTabBarRow(src: std.builtin.SourceLocation) !*dvui.BoxWidget {
    return dvui.box(src, .horizontal, .{ .expand = .horizontal, .background = false });
}

// A verticalTabBarColumn contains is the vertical tab-bar.
// The verticalTabBarColumn lies left of the tab-content area.
// The caller owns the returned value.
pub fn verticalTabBarColumn(src: std.builtin.SourceLocation) !*dvui.BoxWidget {
    return dvui.box(src, .vertical, .{ .expand = .vertical, .background = false });
}

// Tab scrollers.

// The horizontal scroller scrolls tabs sideways.
// The caller owns the returned value.
// It lies inside the horizontalTabBarRow.
pub fn horizontalTabScroller(src: std.builtin.SourceLocation) !*dvui.ScrollAreaWidget {
    return try dvui.scrollArea(
        src,
        .{
            .horizontal = .auto,
            .vertical = .none,
            .horizontal_bar = .hide,
        },
        .{
            .name = "horizontalTabScroller",
            .expand = .horizontal,
            .color_fill = .{ .name = .fill_window },
        },
    );
}

// The vertical scroller scrolls tabs up and down.
// It lies inside the verticalTabBarColumn.
// The caller owns the returned value.
pub fn verticalTabScroller(src: std.builtin.SourceLocation) !*dvui.ScrollAreaWidget {
    return dvui.scrollArea(
        src,
        .{
            .horizontal = .none,
            .vertical = .auto,
            .vertical_bar = .hide,
        },
        .{
            .name = "verticalTabScroller",
            .expand = .both,
        },
    );
}

// Tab bar.
// The tab-bar contains the back-ground color and the tabs.

// The caller owns the returned value.
pub fn horizontalTabBar(src: std.builtin.SourceLocation) !*TabBarWidget {
    var ret = try dvui.currentWindow().arena.create(TabBarWidget);
    ret.* = TabBarWidget.init(src, .horizontal);
    try ret.install(.{});
    return ret;
}

// The caller owns the returned value.
pub fn verticalTabBar(src: std.builtin.SourceLocation) !*TabBarWidget {
    var ret = try dvui.currentWindow().arena.create(TabBarWidget);
    ret.* = TabBarWidget.init(src, .vertical);
    try ret.install(.{});
    return ret;
}

pub fn init(src: std.builtin.SourceLocation, dir: Direction) TabBarWidget {
    var self = TabBarWidget{};
    const options: dvui.Options = switch (dir) {
        .vertical => verticalDefaults,
        .horizontal => horizontalDefaults,
    };
    self.wd = dvui.WidgetData.init(src, .{}, options);
    self.winId = dvui.subwindowCurrentId();
    self.dir = dir;
    return self;
}

pub fn install(self: *TabBarWidget, opts: struct {}) !void {
    _ = opts;
    _ = dvui.parentSet(self.widget());
    try self.wd.register();
    try self.wd.borderAndBackground(.{});

    const evts = dvui.events();
    for (evts) |*e| {
        if (!dvui.eventMatch(e, .{ .id = self.data().id, .r = self.data().borderRectScale().r }))
            continue;

        self.processEvent(e, false);
    }

    // self.box = dvui.BoxWidget.init(@src(), self.dir, false, self.wd.options.strip().override(.{ .expand = .both, .background = true, .color_fill = .{ .name = .accent } })); // background_color
    self.box = dvui.BoxWidget.init(@src(), self.dir, false, .{ .expand = .both, .background = true, .color_fill = .{ .name = .accent } }); // background_color
    try self.box.install();
}

pub fn close(self: *TabBarWidget) void {
    // bubble this event to close all popups that had subtabBars leading to this
    var e = dvui.Event{ .evt = .{ .close_popup = .{} } };
    self.processEvent(&e, true);
    dvui.refresh(null, @src(), self.data().id);
}

pub fn widget(self: *TabBarWidget) dvui.Widget {
    return dvui.Widget.init(self, data, rectFor, screenRectScale, minSizeForChild, processEvent);
}

pub fn data(self: *TabBarWidget) *dvui.WidgetData {
    return &self.wd;
}

pub fn rectFor(self: *TabBarWidget, id: u32, min_size: dvui.Size, e: dvui.Options.Expand, g: dvui.Options.Gravity) dvui.Rect {
    return dvui.placeIn(self.wd.contentRect().justSize(), dvui.minSize(id, min_size), e, g);
}

pub fn screenRectScale(self: *TabBarWidget, rect: dvui.Rect) dvui.RectScale {
    return self.wd.contentRectScale().rectToRectScale(rect);
}

pub fn minSizeForChild(self: *TabBarWidget, s: dvui.Size) void {
    self.wd.minSizeMax(self.wd.padSize(s));
}

pub fn processEvent(self: *TabBarWidget, e: *dvui.Event, bubbling: bool) void {
    _ = bubbling;
    switch (e.evt) {
        .mouse => |me| {
            switch (me.action) {
                .focus => {},
                .press => {},
                .release => {},
                .motion => {},
                .wheel_y => {},
                .position => {
                    // TODO: set this event to handled if there is an existing subtabBar and motion is towards the popup
                    if (dvui.mouseTotalMotion().nonZero()) {
                        self.mouse_over = true;
                    }
                },
            }
        },
        else => {},
    }

    if (e.bubbleable()) {
        // self.wd.parent.processEvent(e, false);
        self.wd.parent.processEvent(e, true);
    }
}

pub fn deinit(self: *TabBarWidget) void {
    self.box.deinit();
    self.wd.minSizeSetAndRefresh();
    self.wd.minSizeReportToParent();
    _ = dvui.parentSet(self.wd.parent);
}