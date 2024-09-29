const std = @import("std");
const dvui = @import("dvui");

const _main_menu_ = @import("main_menu");
const _modal_params_ = @import("modal_params");
const _startup_ = @import("startup");

const MainView = @import("framers").MainView;
const ScreenPointers = @import("screen_pointers").ScreenPointers;

var allocator: std.mem.Allocator = undefined;
var main_view: *MainView = undefined; // standalone-sdl will deinit.
var screen_pointers: *ScreenPointers = undefined;

pub var main_menu_key_pressed: bool = false;

pub fn init(startup: *_startup_.Frontend) !void {
    // Set up each all screens.
    allocator = startup.allocator;
    main_view = startup.main_view;
    screen_pointers = try ScreenPointers.init(startup.*);
    startup.screen_pointers = screen_pointers;
    try screen_pointers.init_screens(startup.*);
    errdefer screen_pointers.deinit();

    // Initialze the example demo window.
    // KICKZIG TODO:
    // When you no longer want to display the example demo window
    //  you can comment the following line out.
    dvui.Examples.show_demo_window = false;

    // Set the default screen.
    try main_view.show(_main_menu_.startup_screen_tag);
}

pub fn deinit() void {
    screen_pointers.deinit();
}

pub fn frame(arena: std.mem.Allocator) !void {
    if (main_view.currentTag()) |current_tag| {
        switch (current_tag) {
            .Tabbar => {
                if (screen_pointers.Tabbar.?.willFrame()) {
                    // The tab screen will frame.
                    try frame_main_menu(arena);
                    try screen_pointers.Tabbar.?.frame(arena);
                } else {
                    // This tab screen will not frame.
                    // Switch back to the startup screen.
                    if (_main_menu_.startup_screen_tag != .Tabbar) {
                        try main_view.show(_main_menu_.startup_screen_tag);
                        try frame(arena);
                    }
                }
            },
            .Remove => {
                if (screen_pointers.Remove.?.willFrame()) {
                    // The tab screen will frame.
                    try frame_main_menu(arena);
                    try screen_pointers.Remove.?.frame(arena);
                } else {
                    // This tab screen will not frame.
                    // Switch back to the startup screen.
                    if (_main_menu_.startup_screen_tag != .Remove) {
                        try main_view.show(_main_menu_.startup_screen_tag);
                        try frame(arena);
                    }
                }
            },
            .Contacts => {
                if (screen_pointers.Contacts.?.willFrame()) {
                    // The tab screen will frame.
                    try frame_main_menu(arena);
                    try screen_pointers.Contacts.?.frame(arena);
                } else {
                    // This tab screen will not frame.
                    // Switch back to the startup screen.
                    if (_main_menu_.startup_screen_tag != .Contacts) {
                        try main_view.show(_main_menu_.startup_screen_tag);
                        try frame(arena);
                    }
                }
            },
            .Edit => {
                if (screen_pointers.Edit.?.willFrame()) {
                    // The tab screen will frame.
                    try frame_main_menu(arena);
                    try screen_pointers.Edit.?.frame(arena);
                } else {
                    // This tab screen will not frame.
                    // Switch back to the startup screen.
                    if (_main_menu_.startup_screen_tag != .Edit) {
                        try main_view.show(_main_menu_.startup_screen_tag);
                        try frame(arena);
                    }
                }
            },
            .YesNo => {
                if (main_view.isNewModal()) {
                    const modal_args: *_modal_params_.YesNo = @alignCast(@ptrCast(main_view.modalArgs()));
                    try screen_pointers.YesNo.?.setState(modal_args);
                }
                try screen_pointers.YesNo.?.frame(arena);
            },
            .EOJ => {
                if (main_view.isNewModal()) {
                    const modal_args: *_modal_params_.EOJ = @alignCast(@ptrCast(main_view.modalArgs()));
                    try screen_pointers.EOJ.?.setState(modal_args);
                }
                try screen_pointers.EOJ.?.frame(arena);
            },
            .OK => {
                if (main_view.isNewModal()) {
                    const modal_args: *_modal_params_.OK = @alignCast(@ptrCast(main_view.modalArgs()));
                    try screen_pointers.OK.?.setState(modal_args);
                }
                try screen_pointers.OK.?.frame(arena);
            },
            .Choice => {
                if (main_view.isNewModal()) {
                    const modal_args: *_modal_params_.Choice = @alignCast(@ptrCast(main_view.modalArgs()));
                    try screen_pointers.Choice.?.setState(modal_args);
                }
                try screen_pointers.Choice.?.frame(arena);
            },
        }
    }
}

pub fn frame_main_menu(arena: std.mem.Allocator) !void {
    if (!_main_menu_.show_main_menu) {
        // Not showing the main menu in this app.
        return;
    }
    var m = try dvui.menu(@src(), .horizontal, .{ .background = true, .expand = .horizontal });
    defer m.deinit();

    if (try dvui.menuItemIcon(@src(), "menu", dvui.entypo.menu, .{ .submenu = true }, .{ .expand = .none })) |r| {
        var fw = try dvui.floatingMenu(@src(), dvui.Rect.fromPoint(dvui.Point{ .x = r.x, .y = r.y + r.h }), .{});
        defer fw.deinit();

        for (_main_menu_.sorted_main_menu_screen_tags, 0..) |screen_tag, id_extra| {
            const will_frame: bool = switch (screen_tag) {
                .Tabbar => blk: {
                    if (screen_pointers.Tabbar) |screen| {
                        break :blk screen.willFrame();
                    } else {
                        break :blk false;
                    }
                },                .Remove => blk: {
                    if (screen_pointers.Remove) |screen| {
                        break :blk screen.willFrame();
                    } else {
                        break :blk false;
                    }
                },                .Contacts => blk: {
                    if (screen_pointers.Contacts) |screen| {
                        break :blk screen.willFrame();
                    } else {
                        break :blk false;
                    }
                },                .Edit => blk: {
                    if (screen_pointers.Edit) |screen| {
                        break :blk screen.willFrame();
                    } else {
                        break :blk false;
                    }
                },                else => false,
            };
            if (!will_frame) {
                continue;
            }

            const label: []const u8 = switch (screen_tag) {
                .Tabbar => try screen_pointers.Tabbar.?.label(arena),
                .Remove => try screen_pointers.Remove.?.label(arena),
                .Contacts => try screen_pointers.Contacts.?.label(arena),
                .Edit => try screen_pointers.Edit.?.label(arena),
                .YesNo => try screen_pointers.YesNo.?.label(arena),
                .EOJ => try screen_pointers.EOJ.?.label(arena),
                .OK => try screen_pointers.OK.?.label(arena),
                .Choice => try screen_pointers.Choice.?.label(arena),
            };
            defer arena.free(label);

            if (try dvui.menuItemLabel(@src(), label, .{}, .{ .id_extra = id_extra }) != null) {
                m.close();

                return switch (screen_tag) {
                    .Tabbar => main_view.show(screen_tag),
                    .Remove => main_view.show(screen_tag),
                    .Contacts => main_view.show(screen_tag),
                    .Edit => main_view.show(screen_tag),
                    else => blk: {
                        const yesno_args = try _modal_params_.OK.init(
                            arena,
                            "That won't work.",
                            "Can not open modals from the main menu.",
                        );
                        break :blk main_view.showOK(yesno_args);
                    },
                };
            }
        }

        // KICKZIG TODO:
        // When you no longer want to display the developer menu items.
        //  set _main_menu_.show_developer_menu_items to false.
        // Developer menu items.
        if (_main_menu_.show_developer_menu_items) {
            if (try dvui.menuItemLabel(@src(), "DVUI Debug", .{}, .{}) != null) {
                dvui.toggleDebugWindow();
            }
            if (dvui.Examples.show_demo_window) {
                if (try dvui.menuItemLabel(@src(), "Hide the DVUI Demo", .{}, .{}) != null) {
                    dvui.Examples.show_demo_window = false;
                }
            } else {
                if (try dvui.menuItemLabel(@src(), "Show the DVUI Demo", .{}, .{}) != null) {
                    dvui.Examples.show_demo_window = true;
                }
            }
        }

        if (try dvui.menuItemIcon(@src(), "close", dvui.entypo.align_top, .{ .submenu = false }, .{ .expand = .none }) != null) {
            m.close();
            return;
        }
    }

    // look at demo() for examples of dvui widgets, shows in a floating window
    // KICKZIG TODO:
    // When you no longer want to display the example demo window
    //  you can comment the following line out.
    try dvui.Examples.demo();
}