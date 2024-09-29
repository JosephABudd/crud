const std = @import("std");
const dvui = @import("dvui");

const ChoiceItem = @import("modal_params").ChoiceItem;
const ContactListRecord = @import("record").List;
const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const Messenger = @import("messenger.zig").Messenger;
const OKModalParams = @import("modal_params").OK;
const Panels = @import("../panels.zig").Panels;
const ScreenOptions = @import("../screen.zig").Options;

pub const Options = struct {
    contact_list_records: ?[]const *const ContactListRecord = null,

    fn init(allocator: std.mem.Allocator) !*Options {
        var self: *Options = try allocator.create(Options);
        self.contact_list_records = null;
        return self;
    }

    fn deinit(self: *Options, allocator: std.mem.Allocator) void {
        if (self.contact_list_records) |records| {
            for (records) |record| {
                record.deinit();
            }
            allocator.free(records);
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
            settings.contact_list_records,
        );
    }

    // Param contact_list_records is owned by Options.
    fn _reset(
        self: *Options,
        allocator: std.mem.Allocator,
        contact_list_records: ?[]const *const ContactListRecord,
    ) !void {
        if (contact_list_records) |records| {
            // Remove the old records list.
            if (self.contact_list_records) |self_records| {
                for (self_records) |self_record| {
                    self_record.deinit();
                }
                allocator.free(self_records);
            }
            // Set the new records list.
            self.contact_list_records = records;
        }
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

    const null_settings: Options = Options{};

    /// KICKZIG TODO:
    /// fn frame is the View's true purpose.
    /// Layout, Draw, Handle user events.
    /// The arena allocator is for building this frame. Not for state.
    pub fn frame(
        self: *View,
        arena: std.mem.Allocator,
    ) !void {
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
                    .name = "edit select frame",
                },
            ) catch |err| {
                self.exit(@src(), err, "dvui.box");
                return err;
            };
            defer row1.deinit();

            dvui.labelNoFmt(@src(), "Select A Contact To Edit", .{ .font_style = .title }) catch |err| {
                self.exit(@src(), err, "labelNoFmt");
                return err;
            };
        }
        {
            // Row 2: List of contacts.
            const scroller = try dvui.scrollArea(
                @src(),
                .{},
                .{
                    .expand = .both,
                    .name = "vertical scroll area",
                },
            );
            defer scroller.deinit();

            {
                var scroller_layout: *dvui.BoxWidget = try dvui.box(@src(), .vertical, .{ .expand = .both });
                defer scroller_layout.deinit();

                if (self.state.?.contact_list_records) |contact_list_records| {
                    for (contact_list_records, 0..) |contact_list_record, i| {
                        const label = try std.fmt.allocPrint(arena, "{s}\n{s}\n{s}, {s} {s}", .{ contact_list_record.name.?, contact_list_record.address.?, contact_list_record.city.?, contact_list_record.state.?, contact_list_record.zip.? });
                        if (try dvui.button(@src(), label, .{}, .{ .expand = .both, .id_extra = i })) {
                            // user selected this contact.
                            // handleClick does not own contact_list_record.
                            try self.handleClick(contact_list_record);
                        }
                    }
                }
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
            self.exit(@src(), err, "Edit.Select unable to set state");
            return err;
        };
        self.container.?.refresh();
    }

    /// refresh only if this view's panel is showing.
    pub fn refresh(self: *View) void {
        if (self.all_panels.current_panel_tag == .Edit) {
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

    // handleClick does not own contact_list_recorrd.
    // setState will copy it.
    fn handleClick(self: *View, contact_list_record: *const ContactListRecord) !void {
        try self.all_panels.Edit.?.view.?.setState(.{ .contact_list_record = contact_list_record });
        self.all_panels.setCurrentToEdit();
    }

    pub fn hasList(self: *View) bool {
        if (self.state.?.contact_list_records) |contact_list_records| {
            return contact_list_records.len > 0;
        }
        return false;
    }

    pub fn emptyList(self: *View) void {
        self.state.?.contact_list_records = null;
    }
};
