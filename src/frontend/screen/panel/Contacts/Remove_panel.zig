const std = @import("std");
const dvui = @import("dvui");

const _lock_ = @import("lock");
const _messenger_ = @import("messenger.zig");
const _panels_ = @import("panels.zig");
const _various_ = @import("various");
const ContactList = @import("record").List;
const ContactRemove = @import("record").Remove;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;

// KICKZIG TODO:
// Remember. Defers happen in reverse order.
// When updating panel state.
//     self.lock();
//     defer self.unlock(); //  2nd defer: Unlocks.
//     defer self.refresh(); // 1st defer: Refreshes the main view.
//     // DO THE UPDATES.

pub const Panel = struct {
    allocator: std.mem.Allocator, // For persistant state data.
    lock: *_lock_.ThreadLock, // For persistant state data.
    window: *dvui.Window,
    main_view: *MainView,
    container: ?*_various_.Container,
    all_panels: *_panels_.Panels,
    messenger: *_messenger_.Messenger,
    exit: ExitFn,

    contact_list_record: ?*const ContactList,

    const grav: dvui.Options = .{ .gravity_x = 0.5, .gravity_y = 0.5 };

    /// frame this panel.
    /// Layout, Draw, Handle user events.
    /// The arena allocator is for building this frame. Not for state.
    pub fn frame(self: *Panel, arena: std.mem.Allocator) !void {
        _ = arena;

        self.lock.lock();
        defer self.lock.unlock();

        {
            // Row 1: The screen's name.
            // Use the same background as the scroller.
            var row: *dvui.BoxWidget = try dvui.box(
                @src(),
                .horizontal,
                .{
                    .expand = .horizontal,
                    .background = true,
                },
            );
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "Remove a contact.", .{ .font_style = .title });
        }

        var scroller = try dvui.scrollArea(@src(), .{}, .{ .expand = .both });
        defer scroller.deinit();

        var layout: *dvui.BoxWidget = try dvui.box(@src(), .vertical, .{});
        defer layout.deinit();

        {
            // Row 2: This contact's name.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "Name:", .{ .font_style = .heading });
            try dvui.labelNoFmt(@src(), self.contact_list_record.?.name.?, .{});
        }
        {
            // Row 3: This contact's address.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "Address:", .{ .font_style = .heading });
            try dvui.labelNoFmt(@src(), self.contact_list_record.?.address.?, .{});
        }
        {
            // Row 4: This contact's city.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "City:", .{ .font_style = .heading });
            try dvui.labelNoFmt(@src(), self.contact_list_record.?.city.?, .{});
        }
        {
            // Row 5: This contact's state.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "State:", .{ .font_style = .heading });
            try dvui.labelNoFmt(@src(), self.contact_list_record.?.state.?, .{});
        }
        {
            // Row 6: This contact's zip.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "Zip:", .{ .font_style = .heading });
            try dvui.labelNoFmt(@src(), self.contact_list_record.?.zip.?, .{});
        }
        {
            // Row 7: Submit or Cancel.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();
            // Submit button.
            if (try dvui.button(@src(), "Submit.", .{}, .{})) {
                // Submit this form.
                const contact_remove_record: *ContactRemove = try ContactRemove.init(
                    self.allocator,
                    self.contact_list_record.?.id,
                );
                try self.messenger.sendRemoveContact(contact_remove_record);
            }
            // Cancel button which switches to the select panel.
            if (try dvui.button(@src(), "Cancel.", .{}, .{})) {
                // Switch to the select panel or the add panel.
                if (self.all_panels.Select.?.has_records()) {
                    self.all_panels.setCurrentToSelect();
                } else {
                    self.all_panels.setCurrentToAdd();
                }
            }
        }
    }

    pub fn deinit(self: *Panel) void {
        if (self.contact_list_record) |contact_list_record| {
            contact_list_record.deinit();
        }

        // The screen will deinit the container.
        self.lock.deinit();
        self.allocator.destroy(self);
    }

    /// refresh only if this panel and ( container or screen ) are showing.
    pub fn refresh(self: *Panel) void {
        if (self.all_panels.current_panel_tag == .Remove) {
            // This is the current panel.
            if (self.container) |container| {
                // Refresh the container.
                // The container will refresh only if it's the currently viewed screen.
                container.refresh();
            } else {
                // Main view will refresh only if this is the currently viewed screen.
                self.main_view.refreshContacts();
            }
        }
    }

    pub fn setContainer(self: *Panel, container: *_various_.Container) void {
        self.container = container;
    }

    // set is called by the select panel's modalRemoveFn.
    // Param contact_list_record is owned by this fn. See Panel.deinit();
    pub fn set(self: *Panel, contact_list_record: *const ContactList) void {
        self.lock.lock();
        defer self.lock.unlock();
        defer self.refresh();

        if (self.contact_list_record) |old_contact_list_record| {
            old_contact_list_record.deinit();
        }
        self.contact_list_record = contact_list_record;
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, all_panels: *_panels_.Panels, messenger: *_messenger_.Messenger, exit: ExitFn, window: *dvui.Window) !*Panel {
    var panel: *Panel = try allocator.create(Panel);
    panel.lock = try _lock_.init(allocator);
    errdefer {
        allocator.destroy(panel);
    }
    panel.container = null;
    panel.allocator = allocator;
    panel.main_view = main_view;
    panel.all_panels = all_panels;
    panel.messenger = messenger;
    panel.exit = exit;
    panel.window = window;

    // The contact list record.
    panel.contact_list_record = null;

    return panel;
}
