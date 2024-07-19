const std = @import("std");

pub const ThreadLock = struct {
    allocator: std.mem.Allocator,
    depth: usize,
    controler_thread_id: ?std.Thread.Id,
    state_mutex: std.Thread.Mutex, // Protects .depth and .controler_thread_id.
    owner_mutex: std.Thread.Mutex, // Protects the owner of this ThreadLock.

    pub fn deinit(self: *ThreadLock) void {
        self.allocator.destroy(self);
    }

    pub fn lock(self: *ThreadLock) void {
        self.state_mutex.lock();
        const caller_thread_id: std.Thread.Id = std.Thread.getCurrentId();

        if (self.controler_thread_id == null) {
            // No other thread controls the owner_mutex.
            // Adjust state.
            self.controler_thread_id = caller_thread_id;
            self.depth = 1;
            self.state_mutex.unlock();
            // Allow the caller's thread to control the owner_mutex.
            self.owner_mutex.lock();
            return;
        }

        if (self.controler_thread_id.? == caller_thread_id) {
            // The caller's thread already controls the owner_mutex.
            // The caller's thread must continue controlling the owner_mutex.
            // Adjust state.
            self.depth += 1;
            self.state_mutex.unlock();
            return;
        } else {
            // The caller's thread does not control the owner_mutex.
            self.state_mutex.unlock();
            // The owner_mutex must handle this call.
            self.owner_mutex.lock();

            // Now the owner_mutex has given the caller's thread control.
            // Set the state and return;
            self.state_mutex.lock();
            self.controler_thread_id = caller_thread_id;
            self.depth = 1;
            self.state_mutex.unlock();
            return;
        }
    }

    pub fn unlock(self: *ThreadLock) void {
        self.state_mutex.lock();
        defer self.state_mutex.unlock();

        const caller_thread_id: std.Thread.Id = std.Thread.getCurrentId();
        if (self.controler_thread_id) |self_thread_id| {
            // There is a thread controling the owner_mutex.
            if (caller_thread_id != self_thread_id) {
                // The caller's thread does not control the owner_mutex.
                // Ignore this call.
                return;
            } else {
                // The caller's thread controls the owner_mutex.
                // Adjust state.
                self.depth -= 1;
                if (self.depth > 0) {
                    // The caller's thread has more unlocking to do.
                    // The caller's thread must continue controlling the owner_mutex.
                    return;
                } else {
                    // The caller's thread no longer controls the owner_mutex.
                    // Adjust state.
                    self.controler_thread_id = null;
                    self.owner_mutex.unlock();
                    // Now the owner_mutex will handle to control to a waiting thread if there is one.
                }
            }
        } else {
            // No thread controls the thread_lock.
            // The caller's thread does not control the thread_lock.
            // Ignore this call.
            return;
        }
    }
};

pub fn init(allocator: std.mem.Allocator) !*ThreadLock {
    var self: *ThreadLock = try allocator.create(ThreadLock);
    self.allocator = allocator;
    self.controler_thread_id = null;
    self.depth = 0;
    return self;
}
