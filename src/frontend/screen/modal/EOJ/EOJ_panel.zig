const std = @import("std");
const dvui = @import("dvui");

const _closedownjobs_ = @import("closedownjobs");
const _closer_ = @import("closer");
const _lock_ = @import("lock");
const _messenger_ = @import("messenger.zig");
const _panels_ = @import("panels.zig");
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").EOJ;

pub const Panel = struct {
    allocator: std.mem.Allocator,
    window: *dvui.Window,
    main_view: *MainView,
    all_panels: *_panels_.Panels,
    messenger: *_messenger_.Messenger,
    lock: *_lock_.ThreadLock,
    exit: ExitFn,

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

        if (setup_args.exit_jobs.jobs_index > 0) {
            // There are jobs to run.
            self.completed_callbacks = false;

            // Send the jobs to the back-end to process.
            const close_down_jobs: ?[]const *const _closedownjobs_.Job = try setup_args.exit_jobs.slice();
            self.messenger.sendCloseDownJobs(close_down_jobs);
        } else {
            // No jobs to run.
            self.completed_callbacks = true;
            if (self.completed_callbacks) {
                const bg_thread = try std.Thread.spawn(.{}, background_progress, .{ self, self.progress });
                bg_thread.detach();
            }
        }
    }

    pub fn deinit(self: *Panel) void {
        if (self.modal_params) |modal_params| {
            modal_params.deinit();
        }
        self.lock.deinit();
        self.allocator.destroy(self);
    }

    // close removes this modal screen replacing it with the previous screen.
    fn close(self: *Panel) void {
        self.main_view.hideEOJ();
    }

    pub fn update(self: *Panel, status: ?[]const u8, completed_callbacks: bool, progress: f32) void {
        self.lock.lock();
        defer {
            self.lock.unlock();
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
            const bg_thread = std.Thread.spawn(.{}, background_progress, .{ self, self.progress }) catch {
                return;
            };
            bg_thread.detach();
        } else {
            self.progress = progress;
            dvui.refresh(self.window, @src(), null);
        }
    }

    /// frame this panel.
    /// Layout, Draw, Handle user events.
    /// Displays a progress bar.
    /// Continues the progress bar after callbacks are finished running.
    /// Allows the window to close after the progress bar finishes.
    pub fn frame(self: *Panel, arena: std.mem.Allocator) !void {
        _ = arena;
        const theme: *dvui.Theme = dvui.themeGet();

        const padding_options = .{
            .expand = .both,
            .margin = dvui.Rect.all(0),
            .border = dvui.Rect.all(10),
            .padding = dvui.Rect.all(10),
            .corner_radius = dvui.Rect.all(5),
            .color_border = theme.style_accent.color_accent.?, //dvui.options.color(.accent),
        };
        var padding: *dvui.BoxWidget = try dvui.box(@src(), .vertical, padding_options);
        defer padding.deinit();

        var scroller = try dvui.scrollArea(@src(), .{}, .{ .expand = .both });
        defer scroller.deinit();

        var layout: *dvui.BoxWidget = try dvui.box(@src(), .vertical, .{ .expand = .horizontal });
        defer layout.deinit();

        // Row 1. Heading.
        if (self.modal_params.?.heading) |heading| {
            try dvui.labelNoFmt(@src(), heading, .{ .font_style = .title });
        }

        // Row 2. Message.
        if (self.modal_params.?.message) |message| {
            try dvui.labelNoFmt(@src(), message, .{ .font_style = .title_4 });
        }

        self.lock.lock();
        defer {
            self.lock.unlock();
        }

        if (self.modal_params.?.is_fatal) {
            // Row 3. Status.
            // Show the user the updated status if there is one.
            if (self.status_len > 0) {
                try dvui.labelNoFmt(@src(), self.status[0..self.status_len], .{ .font_style = .title_4 });
            }
        }

        // Row 3b Progress.
        try dvui.progress(@src(), .{ .percent = self.progress }, .{ .expand = .horizontal, .gravity_y = 0.5, .corner_radius = dvui.Rect.all(100) });
        if (self.progress >= 1.0) {
            // The progress has completed.
            if (self.modal_params.?.is_fatal) {
                // Caused by a fatal error.
                // Let the user close.
                // Row 4. Display a close button.
                // Close when the user clicks it.
                if (self.completed_callbacks) {
                    // The user clicked this button.
                    // Handle the event.
                    if (try dvui.button(@src(), "CloseDownJobs", .{}, .{})) {
                        // Signal that the app can finally quit.
                        _closer_.eoj();
                    }
                }
            } else {
                // Not caused by a fatal error so just close.
                // Signal that the app can finally quit.
                _closer_.eoj();
            }
        }
    }

    fn background_progress(self: *Panel, self_progress: f32) !void {
        const interval: u64 = 10_000_000;
        var progress: f32 = self_progress;
        while (progress < 1.0) {
            std.time.sleep(interval);
            progress += 0.005;
            {
                self.lock.lock();
                defer {
                    self.lock.unlock();
                }

                if (progress > self.progress) {
                    self.progress = progress;
                    dvui.refresh(self.window, @src(), null);
                }
            }
        }
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, all_panels: *_panels_.Panels, messenger: *_messenger_.Messenger, exit: ExitFn, window: *dvui.Window) !*Panel {
    var panel: *Panel = try allocator.create(Panel);
    panel.lock = try _lock_.init(allocator);
    errdefer allocator.destroy(panel);
    panel.allocator = allocator;
    panel.window = window;
    panel.main_view = main_view;
    panel.all_panels = all_panels;
    panel.messenger = messenger;
    panel.exit = exit;
    panel.modal_params = null;
    panel.status_len = 0;
    panel.completed_callbacks = false;
    panel.progress = 0.0;
    return panel;
}
