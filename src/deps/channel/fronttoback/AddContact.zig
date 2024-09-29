/// Through this channel:
/// Messages flow from the front-end to the back-end:
/// 1. Any front-end messenger can send a "AddContact" message to the subscribed back-end messengers.
/// 2. Every subscribed back-end messenger receives a copy of each "AddContact" message sent from the front-end.
/// This file was generated by kickzig when you added the "AddContact" message.
/// It will be removed when you remove the "AddContact" message.

const std = @import("std");
const GeneralDispatcher = @import("general_dispatcher.zig").GeneralDispatcher;

const ExitFn = @import("various").ExitFn;
pub const Message = @import("message").AddContact;

/// Behavior is call-backs and state.
/// .implementor implements the recieveFn.
/// .receiveFn receives a AddContact message from the back-end.
pub const Behavior = struct {
    implementor: *anyopaque,
    receiveFn: *const fn (implementor: *anyopaque, message: *Message) anyerror!void,
};

pub const Group = struct {
    allocator: std.mem.Allocator = undefined,
    buffer: std.ArrayList(*Message),
    members: std.AutoHashMap(*anyopaque, *Behavior),
    exit: ExitFn,
    buffer_mutex: std.Thread.Mutex,
    dispatcher: *GeneralDispatcher,

    pub fn init(allocator: std.mem.Allocator, dispatcher: *GeneralDispatcher, exit: ExitFn) !*Group {
        var channel: *Group = try allocator.create(Group);
        channel.allocator = allocator;
        channel.dispatcher = dispatcher;
        channel.exit = exit;
        channel.buffer_mutex = std.Thread.Mutex{};
        channel.members = std.AutoHashMap(*anyopaque, *Behavior).init(allocator);
        channel.buffer = std.ArrayList(*Message).init(allocator);
        dispatcher.AddContact = channel;
        return channel;
    }

    pub fn deinit(self: *Group) void {
        // deint each Behavior.
        var iterator = self.members.iterator();
        while (iterator.next()) |entry| {
            const behavior: *Behavior = @ptrCast(entry.value_ptr.*);
            self.allocator.destroy(behavior);
        }
        self.members.deinit();
        // deinit each Message not sent.
        var message: ?*Message = self.buffer.popOrNull();
        while (message != null) {
            message.?.deinit();
            message = self.buffer.popOrNull();
        }
        self.buffer.deinit();
        self.allocator.destroy(self);
    }

    /// initBehavior constructs an empty Behavior.
    pub fn initBehavior(self: *Group) !*Behavior {
        return self.allocator.create(Behavior);
    }

    /// subscribe adds a Behavior that will receiver the message to the Group.
    /// Group owns the Behavior not the caller.
    /// So if there is an error the Behavior is destroyed.
    pub fn subscribe(self: *Group, behavior: *Behavior) !void {
        self.members.put(behavior.implementor, behavior) catch |err| {
            self.allocator.destroy(behavior);
            return err;
        };
    }

    /// unsubscribe removes a Behavior from the Group.
    /// It also destroys the Behavior.
    /// Returns true if anything was removed.
    pub fn unsubscribe(self: *Group, caller: *anyopaque) bool {
        if (self.members.getEntry(caller)) |entry| {
            const behavior: *Behavior = @ptrCast(entry.value_ptr.*);
            self.allocator.destroy(behavior);
            return self.members.remove(caller);
        }
    }

    /// send dispatches the message to the Behaviors in Group.
    /// It dispatches in another thread.
    /// It returns after spawning the thread while the thread runs.
    /// It takes control of the message and deinits it.
    /// Receive functions own the message they receive and must deinit it.
    pub fn send(self: *Group, message: *Message) !void {
        {
            self.buffer_mutex.lock();
            defer self.buffer_mutex.unlock();
            try self.buffer.insert(0, message);
        }
        self.dispatcher.dispatch();
    }

    pub fn dispatch(self: *Group) !void {
        var message: ?*Message = self.nextMessage();
        while (message != null) {
            {
                defer message.?.deinit();
                try self._dispatch(message.?);
            }
            message = self.nextMessage();
        }
    }

    fn nextMessage(self: *Group) ?*Message {
        self.buffer_mutex.lock();
        defer self.buffer_mutex.unlock();
        return self.buffer.popOrNull();
    }

    fn _dispatch(self: *Group, message: *Message) !void {
        var iterator = self.members.iterator();
        while (iterator.next()) |entry| {
            var behavior: *Behavior = entry.value_ptr.*;
            // Send the receiver a copy of the message.
            // The receiver owns the copy and must deinit it.
            const receiver_copy: *Message = message.copy() catch |err| {
                self.exit(@src(), err, "message.copy()");
                return err;
            };
            // The receiveFn must handle it's own error.
            // If the receiveFn returns an error then stop.
            behavior.receiveFn(behavior.implementor, receiver_copy) catch |err| {
                // Error: Stop dispatching.
                return err;
            };
        }
    }
};
