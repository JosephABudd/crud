const std = @import("std");
const dvui = @import("dvui");

const _modal_params_ = @import("modal_params");
const _startup_ = @import("startup");
const sorted_main_menu_screen_tags = @import("main_menu").sorted_main_menu_screen_tags;
const startup_screen_tag = @import("main_menu").startup_screen_tag;

const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;

pub const ScreenTags = @import("screen_tags.zig").ScreenTags;

/// MainView is each and every screen.
pub const MainView = struct {
    allocator: std.mem.Allocator,
    lock: std.Thread.Mutex,
    window: *dvui.Window,
    exit: ExitFn,
    current: ?ScreenTags,
    current_modal_is_new: bool,
    current_is_modal: bool,
    previous: ?ScreenTags,
    modal_args: ?*anyopaque,

    pub fn init(startup: _startup_.Frontend) !*MainView {
        var self: *MainView = try startup.allocator.create(MainView);
        self.lock = std.Thread.Mutex{};

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

        if (!MainView.isMainMenuTag(screen)) {
            return error.NotAMainMenuTag;
        }

        // Only show if not a modal screen.
        return switch (screen) {
            .Remove => self._showRemove(),
            .Contacts => self._showContacts(),
            .Edit => self._showEdit(),
            .Tabbar => self._showTabbar(),
            else => error.CantShowModalScreen,
        };
    }

    pub fn refresh(self: *MainView, screen: ScreenTags) void {
        self.lock.lock();
        defer self.lock.unlock();

        switch (screen) {
            .Remove => self._refreshRemove(),
            .Contacts => self._refreshContacts(),
            .Edit => self._refreshEdit(),
            .Tabbar => self._refreshTabbar(),
            .YesNo => self._refreshYesNo(),
            .OK => self._refreshOK(),
            .Choice => self._refreshChoice(),
            else => {}, // EOJ.
        }
    }

    fn isMainMenuTag(screen: ScreenTags) bool {
        if (screen == startup_screen_tag) {
            return true;
        }
        for (sorted_main_menu_screen_tags) |tag| {
            if (tag == screen) {
                return true;
            }
        }
        return false;
    }


    // The Remove screen.

    /// showRemove makes the Remove screen to the current one.
    pub fn showRemove(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        self._showRemove();
    }

    /// _showRemove makes the Remove screen to the current one.
    fn _showRemove(self: *MainView) void {
        if (!isMainMenuTag(.Remove)) {
            // The .Remove tag is not in the main menu.
            return;
        }

        if (!self.current_is_modal) {
            // The current screen is not modal so replace it.
            self.current = .Remove;
            self.current_is_modal = false;
        }
    }

    /// refreshRemove refreshes the window if the Remove screen is the current one.
    pub fn refreshRemove(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        self._refreshRemove();
    }

    /// _refreshRemove refreshes the window if the Remove screen is the current one.
    pub fn _refreshRemove(self: *MainView) void {
        if (self.current) |current| {
            if (current == .Remove) {
                // Remove is the current screen.
                dvui.refresh(self.window, @src(), null);
            }
        }
    }

    /// refreshRemoveContainerFn refreshes the window if the Remove screen is the current one.
    pub fn refreshRemoveContainerFn(implementor: *anyopaque) void {
        var self: *MainView = @alignCast(@ptrCast(implementor));
        self.refreshRemove();
    }

    /// Convert MainView to a Container interface for the Remove screen.
    pub fn asRemoveContainer(self: *MainView) anyerror!*Container {
        return Container.init(
            self.allocator,
            self,
            null,
            MainView.refreshRemoveContainerFn,
        );
    }
    // The Contacts screen.

    /// showContacts makes the Contacts screen to the current one.
    pub fn showContacts(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        self._showContacts();
    }

    /// _showContacts makes the Contacts screen to the current one.
    fn _showContacts(self: *MainView) void {
        if (!isMainMenuTag(.Contacts)) {
            // The .Contacts tag is not in the main menu.
            return;
        }

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

        self._refreshContacts();
    }

    /// _refreshContacts refreshes the window if the Contacts screen is the current one.
    pub fn _refreshContacts(self: *MainView) void {
        if (self.current) |current| {
            if (current == .Contacts) {
                // Contacts is the current screen.
                dvui.refresh(self.window, @src(), null);
            }
        }
    }

    /// refreshContactsContainerFn refreshes the window if the Contacts screen is the current one.
    pub fn refreshContactsContainerFn(implementor: *anyopaque) void {
        var self: *MainView = @alignCast(@ptrCast(implementor));
        self.refreshContacts();
    }

    /// Convert MainView to a Container interface for the Contacts screen.
    pub fn asContactsContainer(self: *MainView) anyerror!*Container {
        return Container.init(
            self.allocator,
            self,
            null,
            MainView.refreshContactsContainerFn,
        );
    }
    // The Edit screen.

    /// showEdit makes the Edit screen to the current one.
    pub fn showEdit(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        self._showEdit();
    }

    /// _showEdit makes the Edit screen to the current one.
    fn _showEdit(self: *MainView) void {
        if (!isMainMenuTag(.Edit)) {
            // The .Edit tag is not in the main menu.
            return;
        }

        if (!self.current_is_modal) {
            // The current screen is not modal so replace it.
            self.current = .Edit;
            self.current_is_modal = false;
        }
    }

    /// refreshEdit refreshes the window if the Edit screen is the current one.
    pub fn refreshEdit(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        self._refreshEdit();
    }

    /// _refreshEdit refreshes the window if the Edit screen is the current one.
    pub fn _refreshEdit(self: *MainView) void {
        if (self.current) |current| {
            if (current == .Edit) {
                // Edit is the current screen.
                dvui.refresh(self.window, @src(), null);
            }
        }
    }

    /// refreshEditContainerFn refreshes the window if the Edit screen is the current one.
    pub fn refreshEditContainerFn(implementor: *anyopaque) void {
        var self: *MainView = @alignCast(@ptrCast(implementor));
        self.refreshEdit();
    }

    /// Convert MainView to a Container interface for the Edit screen.
    pub fn asEditContainer(self: *MainView) anyerror!*Container {
        return Container.init(
            self.allocator,
            self,
            null,
            MainView.refreshEditContainerFn,
        );
    }
    // The Tabbar screen.

    /// showTabbar makes the Tabbar screen to the current one.
    pub fn showTabbar(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        self._showTabbar();
    }

    /// _showTabbar makes the Tabbar screen to the current one.
    fn _showTabbar(self: *MainView) void {
        if (!isMainMenuTag(.Tabbar)) {
            // The .Tabbar tag is not in the main menu.
            return;
        }

        if (!self.current_is_modal) {
            // The current screen is not modal so replace it.
            self.current = .Tabbar;
            self.current_is_modal = false;
        }
    }

    /// refreshTabbar refreshes the window if the Tabbar screen is the current one.
    pub fn refreshTabbar(self: *MainView) void {
        self.lock.lock();
        defer self.lock.unlock();

        self._refreshTabbar();
    }

    /// _refreshTabbar refreshes the window if the Tabbar screen is the current one.
    pub fn _refreshTabbar(self: *MainView) void {
        if (self.current) |current| {
            if (current == .Tabbar) {
                // Tabbar is the current screen.
                dvui.refresh(self.window, @src(), null);
            }
        }
    }

    /// refreshTabbarContainerFn refreshes the window if the Tabbar screen is the current one.
    pub fn refreshTabbarContainerFn(implementor: *anyopaque) void {
        var self: *MainView = @alignCast(@ptrCast(implementor));
        self.refreshTabbar();
    }

    /// Convert MainView to a Container interface for the Tabbar screen.
    pub fn asTabbarContainer(self: *MainView) anyerror!*Container {
        return Container.init(
            self.allocator,
            self,
            null,
            MainView.refreshTabbarContainerFn,
        );
    }    // The YesNo modal screen.

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

    /// refreshYesNoContainerFn refreshes the window if the YesNo screen is the current one.
    pub fn refreshYesNoContainerFn(implementor: *anyopaque) void {
        var self: *MainView = @alignCast(@ptrCast(implementor));
        self.refreshYesNo();
    }

    /// Convert MainView to a Container interface for the YesNo screen.
    pub fn asYesNoContainer(self: *MainView) anyerror!*Container {
        return Container.init(
            self.allocator,
            self,
            null,
            MainView.refreshYesNoContainerFn,
        );
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

    /// refreshOKContainerFn refreshes the window if the OK screen is the current one.
    pub fn refreshOKContainerFn(implementor: *anyopaque) void {
        var self: *MainView = @alignCast(@ptrCast(implementor));
        self.refreshOK();
    }

    /// Convert MainView to a Container interface for the OK screen.
    pub fn asOKContainer(self: *MainView) anyerror!*Container {
        return Container.init(
            self.allocator,
            self,
            null,
            MainView.refreshOKContainerFn,
        );
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

    /// refreshChoiceContainerFn refreshes the window if the Choice screen is the current one.
    pub fn refreshChoiceContainerFn(implementor: *anyopaque) void {
        var self: *MainView = @alignCast(@ptrCast(implementor));
        self.refreshChoice();
    }

    /// Convert MainView to a Container interface for the Choice screen.
    pub fn asChoiceContainer(self: *MainView) anyerror!*Container {
        return Container.init(
            self.allocator,
            self,
            null,
            MainView.refreshChoiceContainerFn,
        );
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
