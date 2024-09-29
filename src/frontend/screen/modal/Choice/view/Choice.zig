const std = @import("std");
const dvui = @import("dvui");

const Container = @import("various").Container;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const Messenger = @import("messenger.zig").Messenger;
const ModalParams = @import("modal_params").Choice;
const Panels = @import("../panels.zig").Panels;

pub const View = struct {
    allocator: std.mem.Allocator,
    border_color: dvui.Options.ColorOrName,
    window: *dvui.Window,
    main_view: *MainView,
    all_panels: *Panels,
    exit: ExitFn,
    messenger: *Messenger,

    /// KICKZIG TODO:
    /// fn frame is the View's true purpose.
    /// Layout, Draw, Handle user events.
    /// The arena allocator is for building this frame. Not for state.
    pub fn frame(
        self: *View,
        arena: std.mem.Allocator,
        modal_params: *ModalParams,
    ) !void {
        _ = arena;

        // Begin with the view's master layout.
        // A vertical stack.
        // So that the scroll area is always under the heading.
        // Row 1 is the heading.
        // Row 2 is the scroller with it's own vertically stacked content.
        var master_layout: *dvui.BoxWidget = dvui.box(
            @src(),
            .vertical,
            .{
                .expand = .both,
                .background = true,
                .name = "master_layout",
            },
        ) catch |err| {
            self.exit(@src(), err, "dvui.box");
            return err;
        };
        defer master_layout.deinit();

        {
            // Vertical Stack Row 1: The screen's name.
            // Use the same background as the scroller.
            var row1: *dvui.BoxWidget = dvui.box(
                @src(),
                .horizontal,
                .{
                    .expand = .horizontal,
                    .background = true,
                },
            ) catch |err| {
                self.exit(@src(), err, "row1");
                return err;
            };
            defer row1.deinit();

            dvui.labelNoFmt(@src(), "Edit or Remove?", .{ .font_style = .title }) catch |err| {
                self.exit(@src(), err, "row1 label");
                return err;
            };
        }

        {
            // Vertical Stack Row 2: The vertical scroller.
            // The vertical scroller has it's contents vertically stacked.
            var scroller = dvui.scrollArea(@src(), .{}, .{ .expand = .both }) catch |err| {
                self.exit(@src(), err, "scroller");
                return err;
            };
            defer scroller.deinit();

            // Vertically stack the scroller's contents.
            var scroller_layout: *dvui.BoxWidget = dvui.box(@src(), .vertical, .{ .expand = .horizontal }) catch |err| {
                self.exit(@src(), err, "scroller_layout");
                return err;
            };
            defer scroller_layout.deinit();

            // Row 1: User defined title.
            var title = try dvui.textLayout(@src(), .{}, .{ .expand = .horizontal, .font_style = .title_4 });
            try title.addText(modal_params.title, .{});
            title.deinit();

            // Row 2-?: User defined buttons
            const choices = modal_params.choiceItems();
            for (choices, 0..) |choice, i| {
                if (try dvui.button(@src(), choice.label, .{}, .{ .expand = .both, .id_extra = i })) {
                    // The button is clicked so close the window and call back.
                    self.close();
                    if (choice.call_back) |call_back| {
                        call_back(choice.implementor.?, choice.context.?) catch |err| {
                            self.exit(@src(), err, "choice.call_back(choice.implementor, choice.context)");
                        };
                    }
                }
            }
        }
    }

    // close removes this modal screen replacing it with the previous screen.
    fn close(self: *View) void {
        self.main_view.hideChoice();
    }

    /// refresh only if this panel is showing and this screen is showing.
    pub fn refresh(self: *View) void {
        if (self.all_panels.current_panel_tag == .Choice) {
            self.main_view.refreshChoice();
        }
    }

    pub fn init(
        allocator: std.mem.Allocator,
        window: *dvui.Window,
        main_view: *MainView,
        all_panels: *Panels,
        messenger: *Messenger,
        exit: ExitFn,
        theme: *dvui.Theme,
    ) !*View {
        var self: *View = try allocator.create(View);
        errdefer allocator.destroy(self);
        self.allocator = allocator;
        self.window = window;
        self.main_view = main_view;
        self.all_panels = all_panels;
        self.messenger = messenger;
        self.exit = exit;
        self.border_color = theme.style_accent.color_accent.?;
        return self;
    }

    pub fn deinit(self: *View) void {
        self.allocator.destroy(self);
    }
};
