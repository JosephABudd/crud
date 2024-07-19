const std = @import("std");
const dvui = @import("dvui");

const _lock_ = @import("lock");
const _panels_ = @import("panels.zig");
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").YesNo;

pub const Panel = struct {
    allocator: std.mem.Allocator,
    window: *dvui.Window,
    main_view: *MainView,
    all_panels: *_panels_.Panels,
    exit: ExitFn,

    modal_params: ?*ModalParams,

    // This panels owns the modal params.
    pub fn presetModal(self: *Panel, setup_args: *ModalParams) !void {
        if (self.modal_params) |modal_params| {
            modal_params.deinit();
        }
        self.modal_params = setup_args;
    }

    pub fn deinit(self: *Panel) void {
        if (self.modal_params) |modal_params| {
            modal_params.deinit();
        }
        self.allocator.destroy(self);
    }

    // close removes this modal screen and returns to the previous screen.
    fn close(self: *Panel) void {
        self.main_view.hideYesNo();
    }

    /// frame this panel.
    /// Layout, Draw, Handle user events.
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

        var layout: *dvui.BoxWidget = try dvui.box(@src(), .vertical, .{});
        defer layout.deinit();

        // Row 1: The heading.
        try dvui.labelNoFmt(@src(), self.modal_params.?.heading, .{ .font_style = .title });

        // Row 2: This question.
        try dvui.labelNoFmt(@src(), self.modal_params.?.question, .{});

        {
            // Row 3: The buttons.
            var row3_layout: *dvui.BoxWidget = try dvui.box(@src(), .horizontal, .{});
            defer row3_layout.deinit();

            if (try dvui.button(@src(), self.modal_params.?.yes_label, .{}, .{})) {
                // The user clicked this button.
                // Handle the event.
                self.modal_params.?.yes_fn(self.modal_params.?.implementor);
                self.close();
            }

            if (try dvui.button(@src(), self.modal_params.?.no_label, .{}, .{})) {
                // The user clicked this button.
                // Handle the event.
                if (self.modal_params.?.no_fn) |no_fn| {
                    no_fn(self.modal_params.?.implementor);
                }
                self.close();
            }
        }
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, all_panels: *_panels_.Panels, exit: ExitFn, window: *dvui.Window) !*Panel {
    var panel: *Panel = try allocator.create(Panel);
    panel.allocator = allocator;
    panel.window = window;
    panel.main_view = main_view;
    panel.all_panels = all_panels;
    panel.exit = exit;
    panel.modal_params = null;
    return panel;
}