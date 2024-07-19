const std = @import("std");
const dvui = @import("dvui");

const _lock_ = @import("lock");
const _modal_params_ = @import("modal_params");
const _startup_ = @import("startup");
const ExitFn = @import("various").ExitFn;
pub const ScreenTags = @import("screen_tags.zig").ScreenTags;

/// MainView is each and every screen.
pub const MainView = struct {
    allocator: std.mem.Allocator,
    lock: *_lock_.ThreadLock,
    window: *dvui.Window,
    exit: ExitFn,
    current: ?ScreenTags,
    current_modal_is_new: bool,
    current_is_modal: bool,
    previous: ?ScreenTags,
    modal_args: ?*anyopaque,

    pub fn init(startup: _startup_.Frontend) !*MainView {
        var self: *MainView = try startup.allocator.create(MainView);
        self.lock = try _lock_.init(startup.allocator);
        errdefer startup.allocator.destroy(self);

        self.allocator = startup.allocator;
        self.exit = startup.exit;
        self.window = startup.window;

        self.current = null;
        self.previous = null;
        self.current_is_modal = false;
        self.modal_args = null;
        self.current_modal_is_new = false;

        return self;
    }

    pub fn deinit(self: *MainView) void {
        self.lock.deinit();
        self.allocator.destroy(self);
    }

    pub fn isModal(self: *MainView) bool {
        self.lock.lock();
        defer self.lock.unlock();

        return self.current_is_modal;
    }

    pub fn isNewModal(self: *MainView) bool {
        self.lock.lock();
        defer self.lock.unlock();

        const is_new: bool = self.current_modal_is_new;
        self.current_modal_is_new = false;
        return is_new;
    }

    pub fn currentTag(self: *MainView) ?ScreenTags {
        self.lock.lock();
        defer self.lock.unlock();

        return self.current;
    }

    pub fn modalArgs(self: *MainView) ?*anyopaque {
        self.lock.lock();
        defer self.lock.unlock();

        const modal_args = self.modal_args;
        self.modal_args = null;
        return modal_args;
    }

    pub fn show(self: *MainView, screen: ScreenTags) !void {
        self.lock.lock();
        defer self.lock.unlock();

        // Only show if not a modal screen.
        return switch (screen) {
            .Contacts => self.showContacts(),
            else => error.CantShowModalScreen,
        };
    }

    pub fn refresh(self: *MainView, screen: ScreenTags) void {
        self.lock.lock();
        defer self.lock.unlock();

        switch (screen) {
            .Contacts => self.refreshContacts(),
            .YesNo => self.refreshYesNo(),
            .OK => self.refreshOK(),
            .Choice => self.refreshChoice(),
            else => {}, // EOJ.
        }
    }

    // The Contacts screen.

    /// showContacts makes the Contacts screen to the current one.
    pub fn showContacts(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (!self.current_is_modal) {
            // The current screen is not modal so replace it.
            self.current = .Contacts;
            self.current_is_modal = false;
        }
    }

    /// refreshContacts refreshes the window if the Contacts screen is the current one.
    pub fn refreshContacts(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current) |current| {
            if (current == .Contacts) {
                // Contacts is the current screen.
                dvui.refresh(self.window, @src(), null);
            }
        }
    }
    // The YesNo modal screen.

    /// showYesNo starts the YesNo modal screen.
    /// Param args is the YesNo modal args.
    /// showYesNo owns modal_args_ptr.
    pub fn showYesNo(self: *MainView, modal_args_ptr: *anyopaque) void {
        self.lock.lock();
        defer self.lock.unlock();
        defer dvui.refresh(self.window, @src(), null);

        if (self.current_is_modal) {
            // The current modal is still showing.
            return;
        }
        // Save the current screen.
        self.previous = self.current;
        self.current_modal_is_new = true;
        self.current_is_modal = true;
        self.modal_args = modal_args_ptr;
        self.current = .YesNo;
    }

    /// hideYesNo hides the modal screen YesNo.
    pub fn hideYesNo(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current) |current| {
            if (current == .YesNo) {
                // YesNo is the current screen so hide it.
                self.current = self.previous;
                self.current_is_modal = false;
                self.modal_args = null;
                self.previous = null;
            }
        }
    }

    /// refreshYesNo refreshes the window if the YesNo screen is the current one.
    pub fn refreshYesNo(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current) |current| {
            if (current == .YesNo) {
                // YesNo is the current screen.
                dvui.refresh(self.window, @src(), null);
            }
        }
    }
    // The OK modal screen.

    /// showOK starts the OK modal screen.
    /// Param args is the OK modal args.
    /// showOK owns modal_args_ptr.
    pub fn showOK(self: *MainView, modal_args_ptr: *anyopaque) void {
        self.lock.lock();
        defer self.lock.unlock();
        defer dvui.refresh(self.window, @src(), null);

        if (self.current_is_modal) {
            // The current modal is still showing.
            return;
        }
        // Save the current screen.
        self.previous = self.current;
        self.current_modal_is_new = true;
        self.current_is_modal = true;
        self.modal_args = modal_args_ptr;
        self.current = .OK;
    }

    /// hideOK hides the modal screen OK.
    pub fn hideOK(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current) |current| {
            if (current == .OK) {
                // OK is the current screen so hide it.
                self.current = self.previous;
                self.current_is_modal = false;
                self.modal_args = null;
                self.previous = null;
            }
        }
    }

    /// refreshOK refreshes the window if the OK screen is the current one.
    pub fn refreshOK(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current) |current| {
            if (current == .OK) {
                // OK is the current screen.
                dvui.refresh(self.window, @src(), null);
            }
        }
    }
    // The Choice modal screen.

    /// showChoice starts the Choice modal screen.
    /// Param args is the Choice modal args.
    /// showChoice owns modal_args_ptr.
    pub fn showChoice(self: *MainView, modal_args_ptr: *anyopaque) void {
        self.lock.lock();
        defer self.lock.unlock();
        defer dvui.refresh(self.window, @src(), null);

        if (self.current_is_modal) {
            // The current modal is still showing.
            return;
        }
        // Save the current screen.
        self.previous = self.current;
        self.current_modal_is_new = true;
        self.current_is_modal = true;
        self.modal_args = modal_args_ptr;
        self.current = .Choice;
    }

    /// hideChoice hides the modal screen Choice.
    pub fn hideChoice(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current) |current| {
            if (current == .Choice) {
                // Choice is the current screen so hide it.
                self.current = self.previous;
                self.current_is_modal = false;
                self.modal_args = null;
                self.previous = null;
            }
        }
    }

    /// refreshChoice refreshes the window if the Choice screen is the current one.
    pub fn refreshChoice(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current) |current| {
            if (current == .Choice) {
                // Choice is the current screen.
                dvui.refresh(self.window, @src(), null);
            }
        }
    }

    // The EOJ modal screen.

    /// forceEOJ starts the EOJ modal screen even if another modal is shown.
    /// Param args is the EOJ modal args.
    /// forceEOJ owns modal_args_ptr.
    pub fn forceEOJ(self: *MainView, modal_args_ptr: *anyopaque) void {
        self.lock.lock();
        defer self.lock.unlock();

        // Don't save the current screen.
        self.current_modal_is_new = true;
        self.current_is_modal = true;
        self.modal_args = modal_args_ptr;
        self.current = .EOJ;
    }

    /// showEOJ starts the EOJ modal screen.
    /// Param args is the EOJ modal args.
    /// showEOJ owns modal_args_ptr.
    pub fn showEOJ(self: *MainView, modal_args_ptr: *anyopaque) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current_is_modal) {
            // The current modal is not hidden yet.
            return;
        }
        // Don't save the current screen.
        self.current_modal_is_new = true;
        self.current_is_modal = true;
        self.modal_args = modal_args_ptr;
        self.current = .EOJ;
    }

    /// hideEOJ hides the modal screen EOJ.
    pub fn hideEOJ(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current) |current| {
            if (current == .EOJ) {
                // EOJ is the current screen so hide it.
                self.current = self.previous;
                self.current_is_modal = false;
                self.modal_args = null;
                self.previous = null;
            }
        }
    }

    /// refreshEOJ refreshes the window if the EOJ screen is the current one.
    pub fn refreshEOJ(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.current) |current| {
            if (current == .EOJ) {
                // EOJ is the current screen.
                dvui.refresh(self.window, @src(), null);
            }
        }
    }
};