/// This is the back-end's "RebuildContactList" message handler.
/// This messenger must be triggered to send a default "RebuildContactList" message to the front-end.
/// The "RebuildContactList" message is at deps/message/src/RebuildContactList.zig.
/// This file was generated by kickzig when you added the "RebuildContactList" message.
/// This file will be removed by kickzig when you remove the "RebuildContactList" message.
const std = @import("std");

const _channel_ = @import("channel");
const _startup_ = @import("startup");

const Contact = @import("record").List;
const ExitFn = @import("various").ExitFn;
const Message = @import("message").RebuildContactList;
const Store = @import("store").Store;

pub const Messenger = struct {
    allocator: std.mem.Allocator,
    send_channels: *_channel_.BackendToFrontend,
    receive_channels: *_channel_.FrontendToBackend,
    triggers: *_channel_.Trigger,
    exit: ExitFn,
    store: *Store,

    pub fn init(startup: _startup_.Backend) !*Messenger {
        var messenger: *Messenger = try startup.allocator.create(Messenger);
        messenger.allocator = startup.allocator;
        messenger.send_channels = startup.send_channels;
        messenger.receive_channels = startup.receive_channels;
        messenger.triggers = startup.triggers;
        messenger.exit = startup.exit;
        messenger.store = startup.store.?;

        // Subscribe to trigger-send the RebuildContactList message.
        var trigger_behavior = try startup.triggers.RebuildContactList.?.initBehavior();
        errdefer {
            messenger.deinit();
        }
        trigger_behavior.implementor = messenger;
        trigger_behavior.triggerFn = &Messenger.triggerRebuildContactListFn;
        try startup.triggers.RebuildContactList.?.subscribe(trigger_behavior);
        errdefer {
            messenger.deinit();
        }
        return messenger;
    }

    pub fn deinit(self: *Messenger) void {
        self.allocator.destroy(self);
    }

    /// triggerRebuildContactListFn builds and sends the "RebuildContactList" message to the front-end.
    /// It implements _channel_.FrontendToBackend.RebuildContactList.Behavior.triggerFn found in deps/channel/frontend/bf/RebuildContactList.zig.
    /// The front-end must not send a response back with this message.
    /// This messenger is not able to receive a RebuildContactList message.
    pub fn triggerRebuildContactListFn(implementor: *anyopaque) anyerror!void {
        var self: *Messenger = @alignCast(@ptrCast(implementor));

        const message: *Message = self.triggerJob() catch |err| {
            // Fatal error.
            self.exit(@src(), err, "self.triggerJob()");
            return err;
        };
        // Send the message back to the front-end.
        // The sender owns the message so never deinit the message.
        self.send_channels.RebuildContactList.send(message) catch |err| {
            // Fatal error.
            self.exit(@src(), err, "self.send_channels.RebuildContactList.send(message)");
            return err;
        };
    }

    /// triggerJob creates message to send to the front-end.
    /// Returns the processed message or an error.
    /// KICKZIG TODO: Add the required functionality.
    fn triggerJob(self: *Messenger) !*Message {
        var message: *Message = try Message.init(self.allocator);
        const contacts: ?[]const *const Contact = self.store.contact_table.getAll() catch |err| {
            message.deinit();
            return err;
        };
        defer {
            if (contacts) |cc| {
                for (cc) |c| {
                    c.deinit();
                }
                self.allocator.free(cc);
            }
        }
        try message.backend_payload.set(.{ .contacts = contacts });
        return message;
    }
};
