const std = @import("std");

const _channel_ = @import("channel");
const _message_ = @import("message");

const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const OKModalParams = @import("modal_params").OK;
const Panels = @import("../panels.zig").Panels;
const RemoveContactRecord = @import("record").Remove;
const ScreenOptions = @import("../screen.zig").Options;
const ScreenTags = @import("framers").ScreenTags;

pub const Messenger = struct {
    allocator: std.mem.Allocator,

    main_view: *MainView,
    all_panels: *Panels,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,
    exit: ExitFn,
    screen_options: ScreenOptions,

    pub fn init(
        allocator: std.mem.Allocator,
        main_view: *MainView,
        send_channels: *_channel_.FrontendToBackend,
        receive_channels: *_channel_.BackendToFrontend,
        exit: ExitFn,
        screen_options: ScreenOptions,
    ) !*Messenger {
        var self: *Messenger = try allocator.create(Messenger);
        self.allocator = allocator;
        self.main_view = main_view;
        self.send_channels = send_channels;
        self.receive_channels = receive_channels;
        self.exit = exit;
        self.screen_options = screen_options;

        // The RemoveContact message.
        // * Define the required behavior.
        var remove_contact_behavior = try receive_channels.RemoveContact.initBehavior();
        errdefer allocator.destroy(self);

        remove_contact_behavior.implementor = self;
        remove_contact_behavior.receiveFn = Messenger.receiveRemoveContact;
        // * Subscribe in order to receive the RemoveContact messages.
        try receive_channels.RemoveContact.subscribe(remove_contact_behavior);
        errdefer allocator.destroy(self);

        // The RebuildContactList message.
        // * Define the required behavior.
        var rebuild_contact_list_behavior = try receive_channels.RebuildContactList.initBehavior();
        errdefer {
            allocator.destroy(self);
        }
        rebuild_contact_list_behavior.implementor = self;
        rebuild_contact_list_behavior.receiveFn = &Messenger.receiveRebuildContactList;
        // * Subscribe in order to receive the RebuildContactList messages.
        try receive_channels.RebuildContactList.subscribe(rebuild_contact_list_behavior);
        errdefer {
            allocator.destroy(self);
        }

        return self;
    }

    pub fn deinit(self: *Messenger) void {
        self.allocator.destroy(self);
    }

    // RemoveContact messages.

    pub fn sendRemoveContact(self: *Messenger, contact: *RemoveContactRecord) !void {
        var msg: *_message_.RemoveContact = _message_.RemoveContact.init(self.allocator) catch |err| {
            self.exit(@src(), err, "_message_.RemoveContact.init(self.allocator)");
            return err;
        };
        msg.frontend_payload.set(
            .{
                .contact = contact,
                .screen_tag = ScreenTags.Remove,
            },
        ) catch |err| {
            self.exit(@src(), err, "msg.frontend_payload.set");
            msg.deinit();
            return err;
        };
        // send will deinit msg even if there is an error.
        try self.send_channels.RemoveContact.send(msg);
    }

    // receiveRemoveContact receives the RemoveContact message.
    // It implements a behavior required by receive_channels.RemoveContact.
    // Errors are handled and returned.
    pub fn receiveRemoveContact(implementor: *anyopaque, message: *_message_.RemoveContact) anyerror!void {
        var self: *Messenger = @alignCast(@ptrCast(implementor));
        defer message.deinit();

        if (message.frontend_payload.screen_tag) |screen_tag| {
            if (screen_tag != ScreenTags.Remove) {
                // Not sent by this screen.
                return;
            }
        } else {
            // Not sent by this screen.
            return;
        }

        if (message.backend_payload.user_error_message) |user_error_message| {
            // The back-end is reporting a user error.
            const ok_args = OKModalParams.init(self.allocator, "Error.", user_error_message) catch |err| {
                self.exit(@src(), err, "OKModalParams.init(self.allocator, \"Error.\", user_error_message)");
                return;
            };
            self.main_view.showOK(ok_args);
            return;
        }
        // No user errors.
        self.all_panels.setCurrentToSelect();
        const ok_args = OKModalParams.init(self.allocator, "Success.", "The contact was removed.") catch |err| {
            self.exit(@src(), err, "OKModalParams.init(self.allocator, \"Success.\", \"The contact was removed.\")");
            return;
        };
        self.main_view.showOK(ok_args);
    }

    // RebuildContactList messages.

    // receiveRebuildContactList receives the RebuildContactList message.
    // It implements a behavior required by receive_channels.RebuildContactList.
    // Errors are handled and returned.
    pub fn receiveRebuildContactList(implementor: *anyopaque, message: *_message_.RebuildContactList) anyerror!void {
        var self: *Messenger = @alignCast(@ptrCast(implementor));
        defer message.deinit();
        var select_panel_view = self.all_panels.Select.?.view.?;
        // The select view's state will own the list of contacts so make a copy.
        const copy_contacts = message.backend_payload.copyContacts() catch |err| {
            self.exit(@src(), err, "message.backend_payload.copyContacts()");
            return err;
        };
        if (copy_contacts) |contacts| {
            // select_panel_view.setState(.{ .contact_list_records = @constCast(contacts) }) catch |err| {
            select_panel_view.setState(.{ .contact_list_records = contacts }) catch |err| {
                self.exit(@src(), err, "select_panel_view.set(contacts)");
                return err;
            };
        } else {
            // There are no contacts.
            select_panel_view.emptyList();
        }
        // Determine which panel to show.
        self.all_panels.setCurrentToSelect();
    }
};
