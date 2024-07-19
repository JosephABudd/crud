const std = @import("std");

const _channel_ = @import("channel");
const _message_ = @import("message");
const _modal_params_ = @import("modal_params");
const _panels_ = @import("panels.zig");
const AddContact = @import("record").Add;
const EditContact = @import("record").Edit;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const OKModalParams = @import("modal_params").OK;
const RemoveContact = @import("record").Remove;

pub const Messenger = struct {
    allocator: std.mem.Allocator,

    main_view: *MainView,
    all_panels: *_panels_.Panels,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,
    exit: ExitFn,

    pub fn deinit(self: *Messenger) void {
        self.allocator.destroy(self);
    }

    // RebuildContactList messages.

    // receiveRebuildContactList receives the RebuildContactList message.
    // It implements a behavior required by receive_channels.RebuildContactList.
    // Errors are handled and returned.
    pub fn receiveRebuildContactList(implementor: *anyopaque, message: *_message_.RebuildContactList.Message) anyerror!void {
        std.log.debug("receiveRebuildContactList", .{});
        var self: *Messenger = @alignCast(@ptrCast(implementor));
        defer message.deinit();
        var select_panel = self.all_panels.Select.?;
        const contacts = message.backend_payload.copyContacts() catch |err| {
            self.exit(@src(), err, "message.backend_payload.copyContacts()");
            return err;
        };
        select_panel.set(contacts) catch |err| {
            self.exit(@src(), err, "select_panel.set(contacts)");
            return err;
        };
        if (select_panel.has_records()) {
            self.all_panels.setCurrentToSelect();
        } else {
            self.all_panels.setCurrentToAdd();
        }
    }

    // AddContact messages.

    pub fn sendAddContact(self: *Messenger, contact: *AddContact) !void {
        var msg: *_message_.AddContact.Message = try _message_.AddContact.init(self.allocator);
        try msg.frontend_payload.set(.{ .contact = contact });
        errdefer msg.deinit();
        // send will deinit msg even if there is an error.
        try self.send_channels.AddContact.send(msg);
    }

    // receiveAddContact receives the AddContact message.
    // It implements a behavior required by receive_channels.AddContact.
    // Errors are handled and returned.
    pub fn receiveAddContact(implementor: *anyopaque, message: *_message_.AddContact.Message) anyerror!void {
        var self: *Messenger = @alignCast(@ptrCast(implementor));
        defer message.deinit();

        if (message.backend_payload.user_error_message) |user_error_message| {
            // The back-end is reporting a user error.
            const ok_args = OKModalParams.init(self.allocator, "Error.", user_error_message) catch |err| {
                self.exit(@src(), err, "OKModalParams.init(self.allocator, \"Error.\", user_error_message)");
                return err;
            };
            self.main_view.showOK(ok_args);
            return;
        }
        // No user errors.
        const ok_args = OKModalParams.init(self.allocator, "Success.", "The contact was added.") catch |err| {
            self.exit(@src(), err, "OKModalParams.init(self.allocator, \"Success.\", \"The contact was added.\")");
            return err;
        };
        self.main_view.showOK(ok_args);
        self.all_panels.Add.?.clearBuffer();
    }

    // EditContact messages.

    pub fn sendEditContact(self: *Messenger, contact: *const EditContact) !void {
        var msg: *_message_.EditContact.Message = try _message_.EditContact.init(self.allocator);
        try msg.frontend_payload.set(.{ .contact = contact });
        errdefer msg.deinit();
        // send will deinit msg even if there is an error.
        try self.send_channels.EditContact.send(msg);
    }

    // receiveEditContact receives the EditContact message.
    // It implements a behavior required by receive_channels.EditContact.
    // Errors are handled and returned.
    pub fn receiveEditContact(implementor: *anyopaque, message: *_message_.EditContact.Message) anyerror!void {
        var self: *Messenger = @alignCast(@ptrCast(implementor));
        defer message.deinit();

        if (message.backend_payload.user_error_message) |user_error_message| {
            // The back-end is reporting a user error.
            const ok_args = OKModalParams.init(self.allocator, "Error.", user_error_message) catch |err| {
                self.exit(@src(), err, "OKModalParams.init(self.allocator, \"Error.\", user_error_message)");
                return err;
            };
            self.main_view.showOK(ok_args);
            return;
        }
        // No user errors.
        const ok_args = OKModalParams.init(self.allocator, "Success.", "The contact was updated.") catch |err| {
            self.exit(@src(), err, "OKModalParams.init(self.allocator, \"Success.\", \"The contact was updated.\")");
            return err;
        };
        self.main_view.showOK(ok_args);
        // Display the correct panel. Either select or add.
        if (self.all_panels.Select.?.has_records()) {
            self.all_panels.setCurrentToSelect();
        } else {
            self.all_panels.setCurrentToAdd();
        }
    }

    // RemoveContact messages.

    pub fn sendRemoveContact(self: *Messenger, contact: *RemoveContact) !void {
        var msg: *_message_.RemoveContact.Message = _message_.RemoveContact.init(self.allocator) catch |err| {
            self.exit(@src(), err, "_message_.RemoveContact.init(self.allocator)");
            return err;
        };
        msg.frontend_payload.set(.{ .contact = contact }) catch |err| {
            self.exit(@src(), err, "msg.frontend_payload.set(.{ .contact = contact })");
            msg.deinit();
            return err;
        };
        // send will deinit msg even if there is an error.
        try self.send_channels.RemoveContact.send(msg);
    }

    // receiveRemoveContact receives the RemoveContact message.
    // It implements a behavior required by receive_channels.RemoveContact.
    // Errors are handled and returned.
    pub fn receiveRemoveContact(implementor: *anyopaque, message: *_message_.RemoveContact.Message) anyerror!void {
        var self: *Messenger = @alignCast(@ptrCast(implementor));
        defer message.deinit();

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
        const ok_args = OKModalParams.init(self.allocator, "Success.", "The contact was removed.") catch |err| {
            self.exit(@src(), err, "OKModalParams.init(self.allocator, \"Success.\", \"The contact was removed.\")");
            return;
        };
        self.main_view.showOK(ok_args);
        // Display the correct panel. Either select or add.
        if (self.all_panels.Select.?.has_records()) {
            self.all_panels.setCurrentToSelect();
        } else {
            self.all_panels.setCurrentToAdd();
        }
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, send_channels: *_channel_.FrontendToBackend, receive_channels: *_channel_.BackendToFrontend, exit: ExitFn) !*Messenger {
    var messenger: *Messenger = try allocator.create(Messenger);
    messenger.allocator = allocator;
    messenger.main_view = main_view;
    messenger.send_channels = send_channels;
    messenger.receive_channels = receive_channels;
    messenger.exit = exit;

    // The RebuildContactList message.
    // * Define the required behavior.
    var rebuild_contact_list_behavior = try receive_channels.RebuildContactList.initBehavior();
    errdefer {
        allocator.destroy(messenger);
    }
    rebuild_contact_list_behavior.implementor = messenger;
    rebuild_contact_list_behavior.receiveFn = &Messenger.receiveRebuildContactList;
    // * Subscribe in order to receive the RebuildContactList messages.
    try receive_channels.RebuildContactList.subscribe(rebuild_contact_list_behavior);
    errdefer {
        allocator.destroy(messenger);
    }

    // The AddContact message.
    // * Define the required behavior.
    var add_contact_behavior = try receive_channels.AddContact.initBehavior();
    errdefer {
        allocator.destroy(messenger);
    }
    add_contact_behavior.implementor = messenger;
    add_contact_behavior.receiveFn = Messenger.receiveAddContact;
    // * Subscribe in order to receive the AddContact messages.
    try receive_channels.AddContact.subscribe(add_contact_behavior);
    errdefer {
        allocator.destroy(messenger);
    }

    // The EditContact message.
    // * Define the required behavior.
    var edit_contact_behavior = try receive_channels.EditContact.initBehavior();
    errdefer {
        allocator.destroy(messenger);
    }
    edit_contact_behavior.implementor = messenger;
    edit_contact_behavior.receiveFn = Messenger.receiveEditContact;
    // * Subscribe in order to receive the EditContact messages.
    try receive_channels.EditContact.subscribe(edit_contact_behavior);
    errdefer {
        allocator.destroy(messenger);
    }

    // The RemoveContact message.
    // * Define the required behavior.
    var remove_contact_behavior = try receive_channels.RemoveContact.initBehavior();
    errdefer {
        allocator.destroy(messenger);
    }
    remove_contact_behavior.implementor = messenger;
    remove_contact_behavior.receiveFn = Messenger.receiveRemoveContact;
    // * Subscribe in order to receive the RemoveContact messages.
    try receive_channels.RemoveContact.subscribe(remove_contact_behavior);
    errdefer {
        allocator.destroy(messenger);
    }

    return messenger;
}
