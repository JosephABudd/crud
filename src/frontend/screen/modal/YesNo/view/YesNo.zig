const std = @import("std");
const dvui = @import("dvui");

const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").YesNo;
const Panels = @import("../panels.zig").Panels;

pub const View = struct {
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
        modal_params: *ModalParams,
    ) !void {
        _ = arena;

        var scroller = try dvui.scrollArea(@src(), .{}, .{ .expand = .both });
        defer scroller.deinit();

        var layout: *dvui.BoxWidget = try dvui.box(@src(), .vertical, .{});
        defer layout.deinit();

        // Row 1: The heading.
        try dvui.labelNoFmt(@src(), modal_params.heading, .{ .font_style = .title });

        // Row 2: This question.
        try dvui.labelNoFmt(@src(), modal_params.question, .{});

        {
            // Row 3: The buttons.
            var row3_layout: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row3_layout.deinit();

            if (try dvui.button(@src(), modal_params.yes_label, .{}, .{})) {
                // The user clicked this button.
                // Handle the event.
                modal_params.yes_fn(modal_params.implementor);
                self.close();
            }

            if (try dvui.button(@src(), modal_params.no_label, .{}, .{})) {
                // The user clicked this button.
                // Handle the event.
                if (modal_params.no_fn) |no_fn| {
                    no_fn(modal_params.implementor);
                }
                self.close();
            }
        }
    }

    // close removes this modal screen replacing it with the previous screen.
    fn close(self: *View) void {
        self.main_view.hideYesNo();
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
        self.allocator = allocator;
        self.window = window;
        self.main_view = main_view;
        self.all_panels = all_panels;
        self.exit = exit;
        self.border_color = theme.style_accent.color_accent.?;
        return self;
    }

    pub fn deinit(self: *View) void {
        self.allocator.destroy(self);
    }
};