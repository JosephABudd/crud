const std = @import("std");
const dvui = @import("dvui");

const _lock_ = @import("lock");
const _messenger_ = @import("messenger.zig");
const _panels_ = @import("panels.zig");
const _various_ = @import("various");
const ChoiceItem = @import("modal_params").ChoiceItem;
const ContactList = @import("record").List;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").Choice;

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

    contact_list_records: ?[]const *const ContactList,

    /// frame this panel.
    /// Layout, Draw, Handle user events.
    /// The arena allocator is for building this frame. Not for state.
    pub fn frame(self: *Panel, arena: std.mem.Allocator) !void {
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

            try dvui.labelNoFmt(@src(), "Select a Contact.", .{ .font_style = .title, .gravity_x = 0.0 });
            if (try dvui.buttonIcon(@src(), "AddAContactButton", dvui.entypo.add_to_list, .{}, .{ .gravity_x = 1.0 })) {
                self.all_panels.Add.?.clearBuffer();
                self.all_panels.setCurrentToAdd();
            }
        }
        {
            // Row 2: List of contacts.
            const scroller = try dvui.scrollArea(
                @src(),
                .{},
                .{
                    .expand = .both,
                },
            );
            defer scroller.deinit();

            {
                var scroller_layout: *dvui.BoxWidget = try dvui.box(@src(), .vertical, .{ .expand = .both });
                defer scroller_layout.deinit();

                if (self.contact_list_records) |contact_list_records| {
                    for (contact_list_records, 0..) |contact_list_record, i| {
                        const label = try std.fmt.allocPrint(arena, "{s}\n{s}\n{s}, {s} {s}", .{ contact_list_record.name.?, contact_list_record.address.?, contact_list_record.city.?, contact_list_record.state.?, contact_list_record.zip.? });
                        if (try dvui.button(@src(), label, .{}, .{ .expand = .both, .id_extra = i })) {
                            // user selected this contact.
                            const contact_copy = try contact_list_record.copy();
                            try self.handleClick(contact_copy);
                        }
                    }
                }
            }
        }
    }

    pub fn deinit(self: *Panel) void {
        // The screen will deinit the container.

        if (self.contact_list_records) |deinit_contact_list_records| {
            for (deinit_contact_list_records) |deinit_contact_list_record| {
                deinit_contact_list_record.deinit();
            }
            self.allocator.free(deinit_contact_list_records);
        }
        self.lock.deinit();
        self.allocator.destroy(self);
    }

    /// refresh only if this panel and ( container or screen ) are showing.
    pub fn refresh(self: *Panel) void {
        if (self.all_panels.current_panel_tag == .Select) {
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

    // has_records returns if there are records in the list to display.
    pub fn has_records(self: *Panel) bool {
        self.lock.lock();
        defer self.lock.unlock();

        return (self.contact_list_records != null);
    }

    // set is called by the messenger.
    // on handles and returns any error.
    // Param contact_list_records is owned by this fn.
    pub fn set(self: *Panel, contact_list_records: ?[]const *const ContactList) !void {
        self.lock.lock();
        defer self.lock.unlock();
        defer self.refresh();

        // deinit the old records.
        if (self.contact_list_records) |deinit_contact_list_records| {
            for (deinit_contact_list_records) |deinit_contact_list_record| {
                deinit_contact_list_record.deinit();
            }
            self.allocator.free(deinit_contact_list_records);
        }
        // add the new records;
        self.contact_list_records = contact_list_records;
    }

    // handleClick owns param contact_list_record.
    fn handleClick(self: *Panel, contact_list_record: *const ContactList) !void {
        // Build the arguments for the modal call.
        // Modal args are owned by the modal screen. So do not deinit here.
        var choice_modal_args: *ModalParams = try ModalParams.init(self.allocator, contact_list_record.name.?);
        // Add each choice.
        try choice_modal_args.addChoiceItem(
            "Edit",
            self,
            @constCast(contact_list_record),
            &Panel.modalEditFn,
        );
        try choice_modal_args.addChoiceItem(
            "Remove",
            self,
            @constCast(contact_list_record),
            &Panel.modalRemoveFn,
        );
        try choice_modal_args.addChoiceItem(
            "Cancel",
            null,
            null,
            null,
        );
        // Show the Choice modal screen.
        self.main_view.showChoice(choice_modal_args);
    }

    // Param context is owned by modalEditFn.
    fn modalEditFn(implementor: ?*anyopaque, context: ?*anyopaque) anyerror!void {
        var self: *Panel = @alignCast(@ptrCast(implementor.?));
        const contact_list_record: *const ContactList = @alignCast(@ptrCast(context.?));
        defer contact_list_record.deinit();
        // Pass a copy of the contact_list_record to the edit panel's fn set.
        const edit_panel_contact_copy: *const ContactList = try contact_list_record.copy();
        self.all_panels.Edit.?.set(edit_panel_contact_copy);
        self.all_panels.setCurrentToEdit();
    }

    // Param context is owned by modalRemoveFn.
    fn modalRemoveFn(implementor: ?*anyopaque, context: ?*anyopaque) anyerror!void {
        var self: *Panel = @alignCast(@ptrCast(implementor.?));
        const contact_list_record: *const ContactList = @alignCast(@ptrCast(context.?));
        defer contact_list_record.deinit();
        const remove_panel_contact_copy: *const ContactList = contact_list_record.copy() catch |err| {
            self.exit(@src(), err, "contact_list_record.copy()");
            return err;
        };
        self.all_panels.Remove.?.set(remove_panel_contact_copy);
        self.all_panels.setCurrentToRemove();
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
    panel.contact_list_records = null;
    return panel;
}
