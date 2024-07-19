/// This is the back-end's "AddContact" message handler.
/// This messenger can receive the "AddContact" message from the front-end
///     and then if needed, send the "AddContact" message back to the front-end.
/// The "AddContact" message is at deps/message/src/AddContact.zig.
/// This file was generated by kickzig when you added the "AddContact" message.
/// This file will be removed by kickzig when you remove the "AddContact" message.
/// KICKZIG TODO: Customize fn receiveFn.
const std = @import("std");

const _channel_ = @import("channel");
const _message_ = @import("message");
const _startup_ = @import("startup");
const ExitFn = @import("various").ExitFn;
const Store = @import("store").Store;

pub const Messenger = struct {
    allocator: std.mem.Allocator,
    send_channels: *_channel_.BackendToFrontend,
    receive_channels: *_channel_.FrontendToBackend,
    triggers: *_channel_.Trigger,
    exit: ExitFn,
    store: *Store,

    pub fn deinit(self: *Messenger) void {
        self.allocator.destroy(self);
    }

    /// receiveAddContactFn receives the "AddContact" message from the front-end.
    /// It implements _channel_.FrontendToBackend.AddContact.Behavior.receiveFn found in deps/channel/fronttoback/AddContact.zig.
    /// The receiveAddContactFn owns the message it receives.
    pub fn receiveAddContactFn(implementor: *anyopaque, message: *_message_.AddContact.Message) anyerror!void {
        var self: *Messenger = @alignCast(@ptrCast(implementor));
        defer message.deinit();

        self.receiveJob(message) catch |err| {
            // Fatal error.
            self.exit(@src(), err, "self.receiveJob(message)");
            return err;
        };
        // If required, send a copy of the message back.
        // Send a copy of the message back to the front-end.
        // The channel owns the message so never deinit the message.
        const copy = message.copy() catch |err| {
            // Fatal error.
            self.exit(@src(), err, "message.copy()");
            return err;
        };
        self.send_channels.AddContact.send(copy) catch |err| {
            // Fatal error.
            self.exit(@src(), err, "self.send_channels.AddContact.send(message)");
            return err;
        };
        if (message.backend_payload.user_error_message == null) {
            // No error message for the user so the record was added.
            // The select list must reload.
            try self.triggers.RebuildContactList.?.trigger();
        }
    }

    /// receiveJob fullfills the front-end's request.
    /// Returns nothing or an error.
    /// KICKZIG TODO: Add the required functionality.
    fn receiveJob(self: *Messenger, message: *_message_.AddContact.Message) !void {
        if (message.frontend_payload.contact) |contact| {
            if (contact.name == null) {
                try message.backend_payload.set(
                    .{ .user_error_message = "Name is a required field." },
                );
                return;
            }
            if (contact.address == null) {
                try message.backend_payload.set(
                    .{ .user_error_message = "Address is a required field." },
                );
                return;
            }
            if (contact.city == null) {
                try message.backend_payload.set(
                    .{ .user_error_message = "City is a required field." },
                );
                return;
            }
            if (contact.state == null) {
                try message.backend_payload.set(
                    .{ .user_error_message = "State is a required field." },
                );
                return;
            }
            if (contact.zip == null) {
                try message.backend_payload.set(
                    .{ .user_error_message = "Zip is a required field." },
                );
                return;
            }
            // Store the record.
            try self.store.contact_table.add(contact.name.?, contact.address.?, contact.city.?, contact.state.?, contact.zip.?);
        } else {
            return error.AddContactMessageMissingContact;
        }
    }
};

pub fn init(startup: _startup_.Backend) !*Messenger {
    var messenger: *Messenger = try startup.allocator.create(Messenger);
    messenger.allocator = startup.allocator;
    messenger.send_channels = startup.send_channels;
    messenger.receive_channels = startup.receive_channels;
    messenger.triggers = startup.triggers;
    messenger.exit = startup.exit;
    messenger.store = startup.store.?;

    // Subscribe to receive the AddContact message.
    var receive_behavior = try startup.receive_channels.AddContact.initBehavior();
    errdefer {
        messenger.deinit();
    }
    receive_behavior.implementor = messenger;
    receive_behavior.receiveFn = &Messenger.receiveAddContactFn;
    try startup.receive_channels.AddContact.subscribe(receive_behavior);
    errdefer {
        messenger.deinit();
    }
    return messenger;
}
