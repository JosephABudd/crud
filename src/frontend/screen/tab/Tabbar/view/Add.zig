const std = @import("std");
const dvui = @import("dvui");

const Contact = @import("record").Add;
const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const Messenger = @import("messenger.zig").Messenger;
const OKModalParams = @import("modal_params").OK;
const ScreenOptions = @import("../screen.zig").Options;

pub const Options = struct {
    name_buffer: ?[]u8 = null,
    address_buffer: ?[]u8 = null,
    city_buffer: ?[]u8 = null,
    state_buffer: ?[]u8 = null,
    zip_buffer: ?[]u8 = null,

    fn init(allocator: std.mem.Allocator) !*Options {
        var self = try allocator.create(Options);
        // null members for deinit();
        self.name_buffer = null;
        self.address_buffer = null;
        self.city_buffer = null;
        self.state_buffer = null;
        self.zip_buffer = null;

        self.name_buffer = try allocator.alloc(u8, 256);
        errdefer self.deinit(allocator);
        self.address_buffer = try allocator.alloc(u8, 256);
        errdefer self.deinit(allocator);
        self.city_buffer = try allocator.alloc(u8, 256);
        errdefer self.deinit(allocator);
        self.state_buffer = try allocator.alloc(u8, 256);
        errdefer self.deinit(allocator);
        self.zip_buffer = try allocator.alloc(u8, 256);
        errdefer self.deinit(allocator);

        self.clearBuffers();
        return self;
    }

    fn deinit(self: *Options, allocator: std.mem.Allocator) void {
        // Name.
        if (self.name_buffer) |member| {
            allocator.free(member);
        }
        // Address.
        if (self.address_buffer) |member| {
            allocator.free(member);
        }
        // City.
        if (self.city_buffer) |member| {
            allocator.free(member);
        }
        // State.
        if (self.state_buffer) |member| {
            allocator.free(member);
        }
        // Zip.
        if (self.zip_buffer) |member| {
            allocator.free(member);
        }
        allocator.destroy(self);
    }

    fn reset(
        self: *Options,
        allocator: std.mem.Allocator,
        settings: Options,
    ) !void {
        return self._reset(
            allocator,
            settings.name_buffer,
            settings.address_buffer,
            settings.city_buffer,
            settings.state_buffer,
            settings.zip_buffer,
        );
    }

    fn _reset(
        self: *Options,
        allocator: std.mem.Allocator,
        name_buffer: ?[]u8,
        address_buffer: ?[]u8,
        city_buffer: ?[]u8,
        state_buffer: ?[]u8,
        zip_buffer: ?[]u8,
    ) !void {
        // Contact name.
        if (name_buffer) |reset_value| {
            if (self.name_buffer) |value| {
                allocator.free(value);
            }
            self.name_buffer = try allocator.alloc(u8, reset_value.len);
            errdefer {
                self.name_buffer = null;
                self.deinit();
            }
            @memcpy(@constCast(self.name_buffer.?), reset_value);
        }
        // Contact address.
        if (address_buffer) |reset_value| {
            if (self.address_buffer) |value| {
                allocator.free(value);
            }
            self.address_buffer = try allocator.alloc(u8, reset_value.len);
            errdefer {
                self.address_buffer = null;
                self.deinit();
            }
            @memcpy(@constCast(self.address_buffer.?), reset_value);
        }
        // Contact city.
        if (city_buffer) |reset_value| {
            if (self.city_buffer) |value| {
                allocator.free(value);
            }
            self.city_buffer = try allocator.alloc(u8, reset_value.len);
            errdefer {
                self.city_buffer = null;
                self.deinit();
            }
            @memcpy(@constCast(self.city_buffer.?), reset_value);
        }
        // Contact state.
        if (state_buffer) |reset_value| {
            if (self.state_buffer) |value| {
                allocator.free(value);
            }
            self.state_buffer = try allocator.alloc(u8, reset_value.len);
            errdefer {
                self.state_buffer = null;
                self.deinit();
            }
            @memcpy(@constCast(self.state_buffer.?), reset_value);
        }
        // Contact zip.
        if (zip_buffer) |reset_value| {
            if (self.zip_buffer) |value| {
                allocator.free(value);
            }
            self.zip_buffer = try allocator.alloc(u8, reset_value.len);
            errdefer {
                self.zip_buffer = null;
                self.deinit();
            }
            @memcpy(@constCast(self.zip_buffer.?), reset_value);
        }
    }

    fn clearBuffers(self: *Options) void {
        @memset(self.name_buffer.?, 0);
        @memset(self.address_buffer.?, 0);
        @memset(self.city_buffer.?, 0);
        @memset(self.state_buffer.?, 0);
        @memset(self.zip_buffer.?, 0);
    }

    fn toContact(self: *Options, allocator: std.mem.Allocator) !*Contact {
        const name_buffer_len: usize = std.mem.indexOf(u8, self.name_buffer.?, &[1]u8{0}) orelse self.name_buffer.?.len;
        const address_buffer_len: usize = std.mem.indexOf(u8, self.address_buffer.?, &[1]u8{0}) orelse self.address_buffer.?.len;
        const city_buffer_len: usize = std.mem.indexOf(u8, self.city_buffer.?, &[1]u8{0}) orelse self.city_buffer.?.len;
        const state_buffer_len: usize = std.mem.indexOf(u8, self.state_buffer.?, &[1]u8{0}) orelse self.state_buffer.?.len;
        const zip_buffer_len: usize = std.mem.indexOf(u8, self.zip_buffer.?, &[1]u8{0}) orelse self.zip_buffer.?.len;

        const name: ?[]const u8 = switch (name_buffer_len) {
            0 => null,
            else => self.name_buffer.?[0..name_buffer_len],
        };
        const address: ?[]const u8 = switch (address_buffer_len) {
            0 => null,
            else => self.address_buffer.?[0..address_buffer_len],
        };
        const city: ?[]const u8 = switch (city_buffer_len) {
            0 => null,
            else => self.city_buffer.?[0..city_buffer_len],
        };
        const state: ?[]const u8 = switch (state_buffer_len) {
            0 => null,
            else => self.state_buffer.?[0..state_buffer_len],
        };
        const zip: ?[]const u8 = switch (zip_buffer_len) {
            0 => null,
            else => self.zip_buffer.?[0..zip_buffer_len],
        };

        const contact: *Contact = try Contact.init(
            allocator,
            name,
            address,
            city,
            state,
            zip,
        );
        return contact;
    }
};

pub const View = struct {
    allocator: std.mem.Allocator,
    window: *dvui.Window,
    main_view: *MainView,
    container: ?*Container,
    messenger: *Messenger,
    exit: ExitFn,
    lock: std.Thread.Mutex,
    state: ?*Options,
    screen_options: ScreenOptions,

    /// KICKZIG TODO:
    /// fn frame is the View's true purpose.
    /// Layout, Draw, Handle user events.
    /// The arena allocator is for building this frame. Not for state.
    pub fn frame(
        self: *View,
        arena: std.mem.Allocator,
    ) !void {
        _ = arena;

        self.lock.lock();
        defer self.lock.unlock();

        // Begin with the view's master layout.
        // A vertical stack.
        // So that the scroll area is always under the heading.
        // Row 1 is the heading.
        // Row 2 is the scroller with it's own vertically stacked content.
        var master_layout: *dvui.BoxWidget = dvui.box(
            @src(),
            .vertical,
            .{
                .expand = .both,
                .background = true,
                .name = "master_layout",
            },
        ) catch |err| {
            self.exit(@src(), err, "dvui.box");
            return err;
        };
        defer master_layout.deinit();

        {
            // Vertical Stack Row 1: The panel heading.
            // Use the same background as the scroller.
            var row1: *dvui.BoxWidget = dvui.box(
                @src(),
                .horizontal,
                .{
                    .expand = .horizontal,
                    .background = true,
                },
            ) catch |err| {
                self.exit(@src(), err, "dvui.box");
                return err;
            };
            defer row1.deinit();

            dvui.labelNoFmt(@src(), "Add A New Contact", .{ .font_style = .title }) catch |err| {
                self.exit(@src(), err, "labelNoFmt");
                return err;
            };
        }

        // Vertical Stack Row 2: The vertical scroller.
        // The vertical scroller has it's contents vertically stacked.
        var scroller = dvui.scrollArea(@src(), .{}, .{ .expand = .both }) catch |err| {
            self.exit(@src(), err, "scroller");
            return err;
        };
        defer scroller.deinit();

        // Vertically stack the scroller's contents.
        var scroller_layout: *dvui.BoxWidget = dvui.box(@src(), .vertical, .{ .expand = .horizontal }) catch |err| {
            self.exit(@src(), err, "scroller_layout");
            return err;
        };
        defer scroller_layout.deinit();

        {
            // Scroller's Content Row 1. The contact's name.
            // Row 1 has 2 columns.
            var scroller_row1: *dvui.BoxWidget = dvui.box(@src(), .horizontal, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row1");
                return err;
            };
            defer scroller_row1.deinit();
            // Row 1 Column 1: Label.
            dvui.labelNoFmt(@src(), "Name:", .{ .font_style = .heading }) catch |err| {
                self.exit(@src(), err, "scroller_row1 heading");
                return err;
            };
            // Row 1 Column 2: Input.
            var input = try dvui.textEntry(@src(), .{ .text = self.state.?.name_buffer.? }, .{});
            defer input.deinit();
        }
        {
            // Scroller's Content Row 2. The contact's address.
            // Row 2 has 2 columns.
            var scroller_row2: *dvui.BoxWidget = dvui.box(@src(), .horizontal, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row2");
                return err;
            };
            defer scroller_row2.deinit();
            // Row 2 Column 1: Label.
            dvui.labelNoFmt(@src(), "Address:", .{ .font_style = .heading }) catch |err| {
                self.exit(@src(), err, "scroller_row2 heading");
                return err;
            };
            // Row 2 Column 2: Input.
            var input = try dvui.textEntry(@src(), .{ .text = self.state.?.address_buffer.? }, .{});
            defer input.deinit();
        }
        {
            // Scroller's Content Row 3. The contact's city.
            // Row 3 has 2 columns.
            var scroller_row3: *dvui.BoxWidget = dvui.box(@src(), .horizontal, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row3");
                return err;
            };
            defer scroller_row3.deinit();
            // Row 3 Column 1: Label.
            dvui.labelNoFmt(@src(), "City:", .{ .font_style = .heading }) catch |err| {
                self.exit(@src(), err, "scroller_row3 heading");
                return err;
            };
            // Row 3 Column 2: Input.
            var input = try dvui.textEntry(@src(), .{ .text = self.state.?.city_buffer.? }, .{});
            defer input.deinit();
        }
        {
            // Scroller's Content Row 4. The contact's state.
            // Row 4 has 2 columns.
            var scroller_row4: *dvui.BoxWidget = dvui.box(@src(), .horizontal, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row4");
                return err;
            };
            defer scroller_row4.deinit();
            // Row 4 Column 1: Label.
            dvui.labelNoFmt(@src(), "State:", .{ .font_style = .heading }) catch |err| {
                self.exit(@src(), err, "scroller_row4 heading");
                return err;
            };
            // Row 4 Column 2: Input.
            var input = try dvui.textEntry(@src(), .{ .text = self.state.?.state_buffer.? }, .{});
            defer input.deinit();
        }
        {
            // Scroller's Content Row 5. The contact's zip.
            // Row 5 has 2 columns.
            var scroller_row5: *dvui.BoxWidget = dvui.box(@src(), .horizontal, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row5");
                return err;
            };
            defer scroller_row5.deinit();
            // Row 5 Column 1: Label.
            dvui.labelNoFmt(@src(), "Zip:", .{ .font_style = .heading }) catch |err| {
                self.exit(@src(), err, "scroller_row5 heading");
                return err;
            };
            // Row 5 Column 2: Input.
            var input = try dvui.textEntry(@src(), .{ .text = self.state.?.zip_buffer.? }, .{});
            defer input.deinit();
        }
        {
            // Row 6: Submit button.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();
            // Submit button.
            if (try dvui.button(@src(), "Submit", .{}, .{})) {
                // Submit this form.
                // Create an add contact record to send to the back-end.
                const contact_add_record: *Contact = try self.state.?.toContact(self.allocator);
                // sendAddContact owns contact_add_record.
                try self.messenger.sendAddContact(contact_add_record, @alignCast(@ptrCast(self.container.?.container())), self);
            }
            // Row 7: Cancel button.
            if (try dvui.button(@src(), "Cancel", .{}, .{})) {
                // Clear the form.
                self.state.?.clearBuffers();
            }
        }
    }

    /// The caller owns the returned value.
    pub fn label(self: *View, allocator: std.mem.Allocator) ![]const u8 {
        self.lock.lock();
        defer self.lock.unlock();

        return try std.fmt.allocPrint(allocator, "{s}", .{"Add"});
    }

    pub fn init(
        allocator: std.mem.Allocator,
        window: *dvui.Window,
        main_view: *MainView,
        messenger: *Messenger,
        exit: ExitFn,
        screen_options: ScreenOptions,
    ) !*View {
        var self: *View = try allocator.create(View);
        errdefer allocator.destroy(self);
        self.allocator = allocator;

        // Initialize state.
        self.state = try Options.init(allocator);
        errdefer {
            self.state = null;
            self.deinit();
        }

        self.window = window;
        self.main_view = main_view;
        self.container = null; // Will be set by Tab.
        self.messenger = messenger;
        self.exit = exit;
        self.lock = std.Thread.Mutex{};
        self.screen_options = screen_options;
        return self;
    }

    /// When a container closes it deinits.
    /// When a container deinits, it deinits it's content.
    pub fn deinit(self: *View) void {
        if (self.state) |member| {
            member.deinit(self.allocator);
        }
        self.allocator.destroy(self);
    }

    /// setState uses the not null members of param settings to modify self.state.
    /// param settings is owned by the caller.
    pub fn setState(self: *View, settings: Options) !void {
        self.lock.lock();
        defer self.lock.unlock();

        self.state.?.reset(self.allocator, settings) catch |err| {
            self.exit(@src(), err, "Tabbar.Add unable to set state");
            return err;
        };
        self.container.?.refresh();
    }

    /// The caller does not own the returned value.
    /// The return value is read only.
    pub fn getState(self: *View) !*Options {
        self.lock.lock();
        defer self.lock.unlock();

        return self.state.?.*;
    }

    pub fn willFrame(self: *View) bool {
        _ = self;
        return true;
    }

    pub fn clearForm(self: *View) void {
        self.lock.lock();
        defer self.lock.unlock();

        self.state.?.clearBuffers();
    }
};
