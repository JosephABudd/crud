const std = @import("std");
const _closedownjobs_ = @import("closedownjobs");

/// Params is the parameters for the EOJ modal screen's state.
/// See src/frontend/screen/modal/EOJ/screen.zig setState.
/// Your arguments are the values assigned to each Params member.
/// For examples:
/// * See OK.zig for a Params example.
/// * See src/frontend/screen/modal/OK/screen.zig setState.
pub const Params = struct {
    allocator: std.mem.Allocator,
    exit_jobs: *_closedownjobs_.Jobs,
    message: ?[]const u8,
    heading: ?[]const u8,
    is_fatal: bool,
    progress: f32,

    // Parameters.

    /// The caller owns the returned value.
    pub fn init(allocator: std.mem.Allocator, exit_jobs: *_closedownjobs_.Jobs) !*Params {
        var args: *Params = try allocator.create(Params);
        args.allocator = allocator;
        args.exit_jobs = exit_jobs;
        args.is_fatal = false;
        args.heading = null;
        args.message = null;
        return args;
    }

    pub fn setHeading(self: *Params, text: []const u8) void {
        self.heading = self.allocator.alloc(u8, text.len) catch {
            return;
        };
        @memcpy(@constCast(self.heading.?), text);
    }

    pub fn setMessage(self: *Params, text: []const u8) void {
        self.message = self.allocator.alloc(u8, text.len) catch {
            return;
        };
        @memcpy(@constCast(self.message.?), text);
    }

    pub fn deinit(self: *Params) void {
        if (self.heading) |heading| {
            self.allocator.free(heading);
        }
        if (self.message) |message| {
            self.allocator.free(message);
        }
        // exit_jobs are deinited in standalone-sdl.
        // do not deinit exit_jobs.
        self.allocator.destroy(self);
    }

    // addJob adds a job to be run before exit.
    pub fn addJob(
        self: *Params,
        title: []const u8,
        implementor: *anyopaque,
        function: *fn () void,
    ) !void {
        const job: *Job = try Job.init(self.allocator, title, implementor, function);
        try self.jobs.append(job);
    }
};

const Job = struct {
    allocator: std.mem.Allocator,
    title: []const u8,
    implementor: *anyopaque,
    job: *fn () void,

    pub fn init(
        allocator: std.mem.Allocator,
        title: []const u8,
        implementor: *anyopaque,
        job: *fn () void,
    ) !*Job {
        var self: *Job = try allocator.create(Job);
        self.title = try allocator.alloc(u8, title.len);
        @memcpy(@constCast(self.title), title);
        self.allocator = allocator;
        self.implementor = implementor;
        self.job = job;
        return self;
    }

    pub fn deinit(self: *Job) void {
        self.allocator.free(self.title);
        self.allocator.destroy(self);
    }
};
