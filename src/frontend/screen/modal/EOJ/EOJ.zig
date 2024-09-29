const std = @import("std");
const dvui = @import("dvui");

const _closedownjobs_ = @import("closedownjobs");

const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").EOJ;
const Panels = @import("panels.zig").Panels;
const View = @import("view/EOJ.zig").View;

pub const Panel = struct {
    allocator: std.mem.Allocator,
    window: *dvui.Window,
    main_view: *MainView,
    all_panels: *Panels,
    lock: std.Thread.Mutex,
    exit: ExitFn,
    view: ?*View,

    modal_params: ?*ModalParams,

    status: [255]u8,
    status_len: usize,
    completed_callbacks: bool,
    progress: f32,

    pub fn presetModal(self: *Panel, setup_args: *ModalParams) !void {
        if (self.modal_params != null) {
            // EOJ is single use only.
            setup_args.deinit();
            return;
        }

        self.modal_params = setup_args;
        self.status_len = 0;
        self.progress = 0.0;
        self.completed_callbacks = setup_args.exit_jobs.jobs_index == 0;

        if (self.completed_callbacks) {
            // No jobs to run.
            // Show the progress bar progressing.
            const bg_thread = try std.Thread.spawn(.{}, finish_showing_progress_bar, .{ self, self.progress });
            bg_thread.detach();
        } else {
            // There are jobs to run.
            // Send the jobs to the back-end to process.
            const close_down_jobs: ?[]const *const _closedownjobs_.Job = try setup_args.exit_jobs.slice();
            if (close_down_jobs) |jobs| {
                // fn runCloseDownJobs will free jobs.
                const bg_thread = try std.Thread.spawn(.{}, runCloseDownJobs, .{ self, jobs });
                bg_thread.detach();
            } else {
                // No jobs to run.
                // Show the progress bar progressing.
                const bg_thread = try std.Thread.spawn(.{}, finish_showing_progress_bar, .{ self, self.progress });
                bg_thread.detach();
            }
        }
    }

    fn runCloseDownJobs(self: *Panel, jobs: []const *const _closedownjobs_.Job) !void {
        defer self.allocator.free(jobs);

        const last = jobs.len - 1;
        const last_f32: f32 = @as(f32, @floatFromInt(jobs.len));
        var current_f32: f32 = 0.0;
        for (jobs, 0..) |job, i| {
            current_f32 += 1.0;
            job.job(job.context);
            const status_update: []u8 = try std.fmt.allocPrint(self.allocator, "Finishing up. Completed {d} of {d} jobs.", .{ (i + 1), jobs.len });
            defer self.allocator.free(status_update);
            // Another job has been run so update the view.
            self.update(status_update, (i == last), (current_f32 / last_f32));
        }
    }

    pub fn init(allocator: std.mem.Allocator, main_view: *MainView, all_panels: *Panels, exit: ExitFn, window: *dvui.Window, theme: *dvui.Theme) !*Panel {
        var self: *Panel = try allocator.create(Panel);
        self.lock = std.Thread.Mutex{};
        self.view = try View.init(
            allocator,
            window,
            main_view,
            all_panels,
            exit,
            theme,
        );
        errdefer {
            self.view = null;
            self.deinit();
        }
        self.allocator = allocator;
        self.window = window;
        self.main_view = main_view;
        self.all_panels = all_panels;
        self.exit = exit;
        self.modal_params = null;
        self.status_len = 0;
        self.completed_callbacks = false;
        self.progress = 0.0;
        return self;
    }

    pub fn deinit(self: *Panel) void {
        if (self.view) |member| {
            member.deinit();
        }
        if (self.modal_params) |member| {
            member.deinit();
        }
        self.allocator.destroy(self);
    }

    // close removes this modal screen replacing it with the previous screen.
    fn close(self: *Panel) void {
        self.main_view.hideEOJ();
    }

    pub fn update(self: *Panel, status: ?[]const u8, completed_callbacks: bool, progress: f32) void {
        // Block fn frame.
        self.lock.lock();
        var locked: bool = true;
        defer {
            if (locked) {
                self.lock.unlock();
            }
        }

        if (status) |text| {
            if (text.len > 0) {
                self.status_len = @min(text.len, 255);
                for (0..self.status_len) |i| {
                    self.status[i] = text[i];
                }
            } else {
                self.status_len = 0;
            }
        } else {
            self.status_len = 0;
        }
        self.completed_callbacks = completed_callbacks;
        if (self.completed_callbacks) {
            locked = false;
            self.lock.unlock();
            try self.finish_showing_progress_bar(self.progress);
        } else {
            // Update progress and call refresh();
            self.progress = progress;
            dvui.refresh(self.window, @src(), null);
        }
    }

    /// frame this panel.
    /// See fn view.frame.
    pub fn frame(self: *Panel, arena: std.mem.Allocator) !void {
        self.lock.lock();
        defer self.lock.unlock();

        return self.view.?.frame(
            arena,
            self.modal_params,
            self.status,
            self.status_len,
            self.completed_callbacks,
            self.progress,
        );
    }

    /// Called when there are no more jobs to run.
    fn finish_showing_progress_bar(self: *Panel, self_progress: f32) !void {
        const interval: u64 = 10_000_000;
        var current_progress: f32 = self_progress;
        var progress: f32 = current_progress;
        while (progress < 1.0) {
            std.time.sleep(interval);
            progress += 0.005;
            {
                if (progress > current_progress) {
                    current_progress = progress;
                    // Block fn frame.
                    self.lock.lock();
                    self.progress = current_progress;
                    self.lock.unlock();
                    dvui.refresh(self.window, @src(), null);
                    // Lock released for fn frame(...);
                }
            }
        }
    }
};