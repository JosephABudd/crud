const std = @import("std");
const dvui = @import("dvui");

const ContactRemoveRecord = @import("record").Remove;
const ContactListRecord = @import("record").List;
const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const Messenger = @import("messenger.zig").Messenger;
const OKModalParams = @import("modal_params").OK;
const Panels = @import("../panels.zig").Panels;
const ScreenOptions = @import("../screen.zig").Options;

pub const Options = struct {
    contact_list_record: ?*const ContactListRecord = null,

    fn init(allocator: std.mem.Allocator) !*Options {
        var self = try allocator.create(Options);
        // null members for deinit();
        self.contact_list_record = null;
        return self;
    }

    /// The caller owns the returned value.
    fn label(self: *Options, allocator: std.mem.Allocator) ![]const u8 {
        _ = self;
        // In this case Options has nothing to do with label.
        // KICKZIG TODO:
        // You may have another way of producing a label.
        return try std.fmt.allocPrint(allocator, "{s}", .{"Remove"});
    }

    fn copyOf(values: Options, allocator: std.mem.Allocator) !*Options {
        var copy_of: *Options = try allocator.create(Options);
        // Null optional members for fn reset.
        copy_of.contact_list_record = null;
        try copy_of.reset(allocator, values);
        errdefer copy_of.deinit();
        return copy_of;
    }

    pub fn deinit(self: *Options, allocator: std.mem.Allocator) void {
        if (self.contact_list_record) |member| {
            member.deinit();
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
            settings.contact_list_record,
        );
    }

    fn resetWithScreenOptions(
        self: *Options,
        allocator: std.mem.Allocator,
        screen_options: ScreenOptions,
    ) !void {
        // Not using screen_options to set state.
        _ = self;
        _ = allocator;
        _ = screen_options;
    }

    fn _reset(
        self: *Options,
        allocator: std.mem.Allocator,
        contact_list_record: ?*const ContactListRecord,
    ) !void {
        _ = allocator;

        if (contact_list_record == null) {
            return;
        }

        // The contact_list_record.
        if (self.contact_list_record) |member| {
            member.deinit();
        }
        self.contact_list_record = try contact_list_record.?.copy();
    }

    fn toContact(self: *Options, allocator: std.mem.Allocator) !*ContactRemoveRecord {
        return ContactRemoveRecord.init(
            allocator,
            self.contact_list_record.?.id,
        );
    }
};

pub const View = struct {
    allocator: std.mem.Allocator,
    window: *dvui.Window,
    main_view: *MainView,
    container: ?*Container,
    all_panels: *Panels,
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

            dvui.labelNoFmt(@src(), "Remove A Contact", .{ .font_style = .title }) catch |err| {
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
            dvui.labelNoFmt(@src(), self.state.?.contact_list_record.?.name.?, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row1 text");
                return err;
            };
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
            dvui.labelNoFmt(@src(), self.state.?.contact_list_record.?.address.?, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row2 text");
                return err;
            };
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
            dvui.labelNoFmt(@src(), self.state.?.contact_list_record.?.city.?, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row3 text");
                return err;
            };
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
            dvui.labelNoFmt(@src(), self.state.?.contact_list_record.?.state.?, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row4 text");
                return err;
            };
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
            dvui.labelNoFmt(@src(), self.state.?.contact_list_record.?.zip.?, .{}) catch |err| {
                self.exit(@src(), err, "scroller_row5 text");
                return err;
            };
        }
        {
            // Row 6: Submit button.
            var row: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row.deinit();
            // Submit button.
            if (try dvui.button(@src(), "Submit", .{}, .{})) {
                // Submit this form.
                // Create an add contact record to send to the back-end.
                const contact_remove_record: *ContactRemoveRecord = self.state.?.toContact(self.allocator) catch |err| {
                    self.exit(@src(), err, "self.state.?.toContact");
                    return err;
                };
                // sendRemoveContact owns contact_remove_record.
                try self.messenger.sendRemoveContact(contact_remove_record);
            }
            // Row 7: Cancel button.
            if (try dvui.button(@src(), "Cancel", .{}, .{})) {
                // Switch to the select panel if there are contacts.
                self.all_panels.setCurrentToSelect();
            }
        }
    }

    pub fn init(
        allocator: std.mem.Allocator,
        window: *dvui.Window,
        main_view: *MainView,
        container: ?*Container,
        all_panels: *Panels,
        messenger: *Messenger,
        exit: ExitFn,
        screen_options: ScreenOptions,
    ) !*View {
        var self: *View = try allocator.create(View);
        self.allocator = allocator;

        // Initialize state.
        self.state = try Options.init(allocator);
        errdefer {
            self.state = null;
            self.deinit();
        }

        self.window = window;
        self.main_view = main_view;
        self.container = container;
        self.all_panels = all_panels;
        self.messenger = messenger;
        self.exit = exit;
        self.lock = std.Thread.Mutex{};
        self.screen_options = screen_options;
        return self;
    }

    pub fn deinit(self: *View) void {
        if (self.state) |state| {
            state.deinit(self.allocator);
        }
        self.allocator.destroy(self);
    }

    /// setState uses the not null members of param settings to modify self.state.
    /// param settings is owned by the caller.
    pub fn setState(self: *View, settings: Options) !void {
        self.lock.lock();
        defer self.lock.unlock();

        self.state.?.reset(self.allocator, settings) catch |err| {
            self.exit(@src(), err, "Remove.Remove unable to set state");
            return err;
        };
        self.container.?.refresh();
    }

    /// refresh only if this view's panel is showing.
    pub fn refresh(self: *View) void {
        if (self.all_panels.current_panel_tag == .Remove) {
            // This is the current panel.
            self.container.?.refresh();
        }
    }

    pub fn setContainer(self: *View, container: *Container) !void {
        if (self.container != null) {
            return error.ContainerAlreadySet;
        }
        self.container = container;
    }
};
