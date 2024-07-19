const std = @import("std");
const dvui = @import("dvui");

const _lock_ = @import("lock");
const _messenger_ = @import("messenger.zig");
const _panels_ = @import("panels.zig");
const _various_ = @import("various");
const Contact = @import("record").Add;
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

    name_buffer: []u8,
    address_buffer: []u8,
    city_buffer: []u8,
    state_buffer: []u8,
    zip_buffer: []u8,

    /// frame this panel.
    /// Layout, Draw, Handle user events.
    /// The arena allocator is for building this frame. Not for state.
    pub fn frame(self: *Panel, arena: std.mem.Allocator) !void {
        _ = arena;

        self.lock.lock();
        defer self.lock.unlock();

        {
            // Row 1: The screen's name.
            // This row has a background because the scroller has a background.
            var row: *dvui.BoxWidget = try dvui.box(
                @src(),
                .horizontal,
                .{
                    .expand = .horizontal,
                    .background = true,
                },
            );
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "Add a new contact.", .{ .font_style = .title });
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
            var input = try dvui.textEntry(@src(), .{ .text = self.name_buffer }, .{});
            defer input.deinit();
        }
        {
            // Row 3: This contact's address.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "Address:", .{ .font_style = .heading });
            var input = try dvui.textEntry(@src(), .{ .text = self.address_buffer }, .{});
            defer input.deinit();
        }
        {
            // Row 4: This contact's city.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "City:", .{ .font_style = .heading });
            var input = try dvui.textEntry(@src(), .{ .text = self.city_buffer }, .{});
            defer input.deinit();
        }
        {
            // Row 5: This contact's state.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "State:", .{ .font_style = .heading });
            var input = try dvui.textEntry(@src(), .{ .text = self.state_buffer }, .{});
            defer input.deinit();
        }
        {
            // Row 6: This contact's zip.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();

            try dvui.labelNoFmt(@src(), "Zip:", .{ .font_style = .heading });
            var input = try dvui.textEntry(@src(), .{ .text = self.zip_buffer }, .{});
            defer input.deinit();
        }
        {
            // Row 7: Submit button.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();
            // Submit button.
            if (try dvui.button(@src(), "Submit.", .{}, .{})) {
                // Submit this form.
                // Create an add contact record to send to the back-end.
                const contact_add_record: *Contact = try self.bufferToContact();
                // sendAddContact owns contact_add_record.
                try self.messenger.sendAddContact(contact_add_record);
            }
            // Row 8: Cancel button.
            if (try dvui.button(@src(), "Cancel.", .{}, .{})) {
                // Clear the form.
                self.clearBuffer();
                // Switch to the select panel if there are contacts.
                if (self.all_panels.Select.?.has_records()) {
                    self.all_panels.setCurrentToSelect();
                }
            }
        }
    }

    pub fn deinit(self: *Panel) void {
        self.allocator.free(self.name_buffer);
        self.allocator.free(self.address_buffer);
        self.allocator.free(self.city_buffer);
        self.allocator.free(self.state_buffer);
        self.allocator.free(self.zip_buffer);

        // The screen will deinit the container.
        self.lock.deinit();
        self.allocator.destroy(self);
    }

    /// refresh only if this panel and ( container or screen ) are showing.
    pub fn refresh(self: *Panel) void {
        if (self.all_panels.current_panel_tag == .Add) {
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

    pub fn clearBuffer(self: *Panel) void {
        @memset(self.name_buffer, 0);
        @memset(self.address_buffer, 0);
        @memset(self.city_buffer, 0);
        @memset(self.state_buffer, 0);
        @memset(self.zip_buffer, 0);
    }

    fn bufferToContact(self: *Panel) !*Contact {
        const name_buffer_len: usize = std.mem.indexOf(u8, self.name_buffer, &[1]u8{0}) orelse self.name_buffer.len;
        const address_buffer_len: usize = std.mem.indexOf(u8, self.address_buffer, &[1]u8{0}) orelse self.address_buffer.len;
        const city_buffer_len: usize = std.mem.indexOf(u8, self.city_buffer, &[1]u8{0}) orelse self.city_buffer.len;
        const state_buffer_len: usize = std.mem.indexOf(u8, self.state_buffer, &[1]u8{0}) orelse self.state_buffer.len;
        const zip_buffer_len: usize = std.mem.indexOf(u8, self.zip_buffer, &[1]u8{0}) orelse self.zip_buffer.len;

        const name: ?[]const u8 = switch (name_buffer_len) {
            0 => null,
            else => self.name_buffer[0..name_buffer_len],
        };
        const address: ?[]const u8 = switch (address_buffer_len) {
            0 => null,
            else => self.address_buffer[0..address_buffer_len],
        };
        const city: ?[]const u8 = switch (city_buffer_len) {
            0 => null,
            else => self.city_buffer[0..city_buffer_len],
        };
        const state: ?[]const u8 = switch (state_buffer_len) {
            0 => null,
            else => self.state_buffer[0..state_buffer_len],
        };
        const zip: ?[]const u8 = switch (zip_buffer_len) {
            0 => null,
            else => self.zip_buffer[0..zip_buffer_len],
        };

        const contact: *Contact = Contact.init(
            self.allocator,
            name,
            address,
            city,
            state,
            zip,
        ) catch |err| {
            self.exit(@src(), err, "Contact.init(...)");
            return err;
        };
        return contact;
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

    // The input buffers.
    panel.name_buffer = try allocator.alloc(u8, 255);
    panel.address_buffer = try allocator.alloc(u8, 255);
    panel.city_buffer = try allocator.alloc(u8, 255);
    panel.state_buffer = try allocator.alloc(u8, 255);
    panel.zip_buffer = try allocator.alloc(u8, 255);
    panel.clearBuffer();

    return panel;
}
