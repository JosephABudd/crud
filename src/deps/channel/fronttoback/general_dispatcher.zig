/// GeneralDispatcher:
/// This file is re-generated by kickzig each time you add or remove a back-to-front or trigger message.
/// Do not edit this file.
const std = @import("std");

const ExitFn = @import("various").ExitFn;
const EditContact = @import("EditContact.zig").Group;
const RemoveContact = @import("RemoveContact.zig").Group;
const AddContact = @import("AddContact.zig").Group;

pub const GeneralDispatcher = struct {
    allocator: std.mem.Allocator = undefined,
    condition: std.Thread.Condition,
    running: bool,
    running_mutex: std.Thread.Mutex,
    loop_mutex: std.Thread.Mutex,
    // Custom channels.
    EditContact: ?*EditContact = null,
    RemoveContact: ?*RemoveContact = null,
    AddContact: ?*AddContact = null,

    pub fn init(allocator: std.mem.Allocator, exit: ExitFn) !*GeneralDispatcher {
        var self: *GeneralDispatcher = try allocator.create(GeneralDispatcher);
        self.allocator = allocator;

        self.loop_mutex = std.Thread.Mutex{};
        self.running_mutex = std.Thread.Mutex{};
        self.condition = std.Thread.Condition{};

        self.EditContact = try EditContact.init(allocator, self, exit);
        errdefer self.deinit();

        self.RemoveContact = try RemoveContact.init(allocator, self, exit);
        errdefer self.deinit();

        self.AddContact = try AddContact.init(allocator, self, exit);
        errdefer self.deinit();


        // Initialize the running.
        self.running = true;
        self.condition.signal();
        const thread = try std.Thread.spawn(.{ .allocator = self.allocator }, GeneralDispatcher.run, .{self});
        std.Thread.detach(thread);
        return self;
    }

    pub fn deinit(self: *GeneralDispatcher) void {
        self.stop();
        if (self.EditContact) |member| {
            member.deinit();
        }
        if (self.RemoveContact) |member| {
            member.deinit();
        }
        if (self.AddContact) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    pub fn dispatch(self: *GeneralDispatcher) void {
        self.condition.signal();
    }

    fn getRunning(self: *GeneralDispatcher) bool {
        self.running_mutex.lock();
        defer self.running_mutex.unlock();

        return self.running;
    }

    fn stop(self: *GeneralDispatcher) void {
        self.running_mutex.lock();
        defer self.running_mutex.unlock();

        if (self.running) {
            self.running = false;
            self.condition.signal();
        }
    }

    fn run(self: *GeneralDispatcher) void {
        self.loop_mutex.lock();
        defer self.loop_mutex.unlock();

        while (self.getRunning()) {
            // Still running so wait for the next condition.
            self.condition.wait(&self.loop_mutex);
            if (self.getRunning()) {
                // Have each channel dispatch its own messages.
                self.EditContact.?.dispatch() catch {
                    // The channel or message receiver handled the errror.
                    return;
                };
                self.RemoveContact.?.dispatch() catch {
                    // The channel or message receiver handled the errror.
                    return;
                };
                self.AddContact.?.dispatch() catch {
                    // The channel or message receiver handled the errror.
                    return;
                };
            }
        }
    }
};
