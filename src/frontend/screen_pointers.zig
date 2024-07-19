const std = @import("std");
const _startup_ = @import("startup");
pub const Contacts = @import("screen/panel/Contacts/screen.zig").Screen;
pub const YesNo = @import("screen/modal/YesNo/screen.zig").Screen;
pub const EOJ = @import("screen/modal/EOJ/screen.zig").Screen;
pub const OK = @import("screen/modal/OK/screen.zig").Screen;
pub const Choice = @import("screen/modal/Choice/screen.zig").Screen;

pub const ScreenPointers = struct {
    allocator: std.mem.Allocator,
    Contacts: ?*Contacts,
    YesNo: ?*YesNo,
    EOJ: ?*EOJ,
    OK: ?*OK,
    Choice: ?*Choice,

    pub fn deinit(self: *ScreenPointers) void {
        if (self.Contacts) |screen| {
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
        return self;
    }

    pub fn init_screens(self: *ScreenPointers, startup: _startup_.Frontend) !void {
        // Set up each screen.
        // Modal screens.
        self.Contacts = try Contacts.init(startup);
        errdefer self.deinit();
        if (!self.Contacts.?.willFrame()) {
            // The Contacts screen won't frame inside the main view.
            // It will only frame in a container.
            // It can't be used in the main menu.
            self.Contacts.?.deinit();
            self.Contacts = null;
        }        // The YesNo screen is a modal screen.
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
