const std = @import("std");

const _main_menu_ = @import("main_menu");
const _startup_ = @import("startup");

const Container = @import("various").Container;
const Content = @import("various").Content;
const ScreenTags = @import("framers").ScreenTags;

pub const Tabbar = @import("screen/tab/Tabbar/screen.zig").Screen;
pub const Remove = @import("screen/panel/Remove/screen.zig").Screen;
pub const Contacts = @import("screen/panel/Contacts/screen.zig").Screen;
pub const Edit = @import("screen/panel/Edit/screen.zig").Screen;
pub const YesNo = @import("screen/modal/YesNo/screen.zig").Screen;
pub const EOJ = @import("screen/modal/EOJ/screen.zig").Screen;
pub const OK = @import("screen/modal/OK/screen.zig").Screen;
pub const Choice = @import("screen/modal/Choice/screen.zig").Screen;

pub const ScreenPointers = struct {
    allocator: std.mem.Allocator,
    Tabbar: ?*Tabbar,
    Remove: ?*Remove,
    Contacts: ?*Contacts,
    Edit: ?*Edit,
    YesNo: ?*YesNo,
    EOJ: ?*EOJ,
    OK: ?*OK,
    Choice: ?*Choice,

    pub fn deinit(self: *ScreenPointers) void {
        if (self.Tabbar) |screen| {
            screen.deinit();
        }
        if (self.Remove) |screen| {
            screen.deinit();
        }
        if (self.Contacts) |screen| {
            screen.deinit();
        }
        if (self.Edit) |screen| {
            screen.deinit();
        }
        if (self.YesNo) |screen| {
            screen.deinit();
        }
        if (self.EOJ) |screen| {
            screen.deinit();
        }
        if (self.OK) |screen| {
            screen.deinit();
        }
        if (self.Choice) |screen| {
            screen.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn init(startup: _startup_.Frontend) !*ScreenPointers {
        const self: *ScreenPointers = try startup.allocator.create(ScreenPointers);
        self.allocator = startup.allocator;
        self.Tabbar = null;
        self.Remove = null;
        self.Contacts = null;
        self.Edit = null;
        self.YesNo = null;
        self.EOJ = null;
        self.OK = null;
        self.Choice = null;
        return self;
    }

    pub fn init_screens(self: *ScreenPointers, startup: _startup_.Frontend) !void {
        const screen_tags: []ScreenTags = try _main_menu_.screenTagsForInitialization(self.allocator);
        defer self.allocator.free(screen_tags);
        for (screen_tags) |tag| {
            switch (tag) {


                .Tabbar => {
                    // KICKZIG TODO: You can customize the init_options. See deps/widgets/tabbar/api.zig.
                    const main_view_as_container: *Container = try startup.main_view.asTabbarContainer();
                    // The 3rd param is a Tabs.Options.
                    // The 4th param is the Tabbar screen Options. See screen/tab/Tabbar.zig Options.
                    self.Tabbar = try Tabbar.init(startup, main_view_as_container, .{}, .{});
                    errdefer main_view_as_container.deinit();
                },

                .Remove => {
                    const main_view_as_container: *Container = try startup.main_view.asRemoveContainer();
                    // The 3rd param is the Remove screen Options. See screen/panel/Remove.zig Options.
                    self.Remove = try Remove.init(startup, main_view_as_container, .{});
                    errdefer main_view_as_container.deinit();
                },

                .Contacts => {
                    const main_view_as_container: *Container = try startup.main_view.asContactsContainer();
                    // The 3rd param is the Contacts screen Options. See screen/panel/Contacts.zig Options.
                    self.Contacts = try Contacts.init(startup, main_view_as_container, .{});
                    errdefer main_view_as_container.deinit();
                },

                .Edit => {
                    const main_view_as_container: *Container = try startup.main_view.asEditContainer();
                    // The 3rd param is the Edit screen Options. See screen/panel/Edit.zig Options.
                    self.Edit = try Edit.init(startup, main_view_as_container, .{});
                    errdefer main_view_as_container.deinit();
                },
                else => {
                    // No modals here. They are below.
                },
            }
        }

        // Set up each modal screen.

        // The YesNo screen is a modal screen.
        // Modal screens frame inside the main view.
        // The YesNo modal screen can not be used in the main menu.
        self.YesNo = try YesNo.init(startup);
        errdefer self.deinit();
        // The EOJ screen is a modal screen.
        // Modal screens frame inside the main view.
        // The EOJ modal screen can not be used in the main menu.
        self.EOJ = try EOJ.init(startup);
        errdefer self.deinit();
        // The OK screen is a modal screen.
        // Modal screens frame inside the main view.
        // It is the only modal screen that can be used in the main menu.
        self.OK = try OK.init(startup);
        errdefer self.deinit();
        // The Choice screen is a modal screen.
        // Modal screens frame inside the main view.
        // The Choice modal screen can not be used in the main menu.
        self.Choice = try Choice.init(startup);
        errdefer self.deinit();
    }
};
