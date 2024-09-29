const std = @import("std");
const dvui = @import("dvui");

const _closer_ = @import("closer");

const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").EOJ;
const Panels = @import("../panels.zig").Panels;

pub const View = struct {
    lock: std.Thread.Mutex,
    allocator: std.mem.Allocator,
    window: *dvui.Window,
    main_view: *MainView,
    all_panels: *Panels,
    exit: ExitFn,
    modal_params: ?*ModalParams,
    border_color: dvui.Options.ColorOrName,

    /// KICKZIG TODO:
    /// fn frame is the View's true purpose.
    /// Layout, Draw, Handle user events.
    /// The arena allocator is for building this frame.
    pub fn frame(
        self: *View,
        arena: std.mem.Allocator,
        modal_params: ?*ModalParams,
        status: [255]u8,
        status_len: usize,
        completed_callbacks: bool,
        progress: f32,
    ) !void {
        _ = arena;

        self.lock.lock();
        defer self.lock.unlock();

        var scroller = try dvui.scrollArea(@src(), .{}, .{ .expand = .both });
        defer scroller.deinit();

        var layout: *dvui.BoxWidget = try dvui.box(@src(), .vertical, .{ .expand = .horizontal });
        defer layout.deinit();

        // Row 1. Heading.
        if (modal_params.?.heading) |heading| {
            try dvui.labelNoFmt(@src(), heading, .{ .font_style = .title });
        }

        // Row 2. Message.
        if (modal_params.?.message) |message| {
            try dvui.labelNoFmt(@src(), message, .{ .font_style = .title_4 });
        }

        if (modal_params.?.is_fatal) {
            // Row 3. Status.
            // Show the user the updated status if there is one.
            if (status_len > 0) {
                try dvui.labelNoFmt(@src(), status[0..status_len], .{ .font_style = .title_4 });
            }
        }

        // Row 3b Progress.
        try dvui.progress(@src(), .{ .percent = progress }, .{ .expand = .horizontal, .gravity_y = 0.5, .corner_radius = dvui.Rect.all(100) });
        if (progress >= 1.0) {
            // The progress has completed.
            if (modal_params.?.is_fatal) {
                // Caused by a fatal error.
                // Let the user close.
                // Row 4. Display a close button.
                // Close when the user clicks it.
                if (completed_callbacks) {
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

    // close removes this modal screen replacing it with the previous screen.
    fn close(self: *View) void {
        self.main_view.hideEOJ();
    }

    pub fn init(
        allocator: std.mem.Allocator,
        window: *dvui.Window,
        main_view: *MainView,
        all_panels: *Panels,
        exit: ExitFn,
        theme: *dvui.Theme,
    ) !*View {
        var self: *View = try allocator.create(View);
        errdefer allocator.destroy(self);
        self.allocator = allocator;
        self.window = window;
        self.main_view = main_view;
        self.all_panels = all_panels;
        self.exit = exit;
        self.border_color = theme.style_accent.color_accent.?;
        self.lock = std.Thread.Mutex{};
        return self;
    }

    pub fn deinit(self: *View) void {
        self.allocator.destroy(self);
    }
};