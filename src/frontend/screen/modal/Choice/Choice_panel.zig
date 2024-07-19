const std = @import("std");
const dvui = @import("dvui");

const _channel_ = @import("channel");
const _lock_ = @import("lock");
const _messenger_ = @import("messenger.zig");
const _panels_ = @import("panels.zig");
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ModalParams = @import("modal_params").Choice;

pub const Panel = struct {
    allocator: std.mem.Allocator, // For persistant state data.
    lock: *_lock_.ThreadLock, // For persistant state data.
    window: *dvui.Window,
    main_view: *MainView,
    all_panels: *_panels_.Panels,
    messenger: *_messenger_.Messenger,
    exit: ExitFn,

    modal_params: ?*ModalParams,

    // This panels owns the modal params.
    pub fn presetModal(self: *Panel, setup_args: *ModalParams) !void {
        if (self.modal_params) |modal_params| {
            modal_params.deinit();
        }
        self.modal_params = setup_args;
    }

    /// refresh only if this panel is showing and this screen is showing.
    pub fn refresh(self: *Panel) void {
        if (self.all_panels.current_panel_tag == .Choice) {
            self.main_view.refreshChoice();
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
        self.main_view.hideChoice();
    }

    /// frame this panel.
    /// Layout, Draw, Handle user events.
    pub fn frame(self: *Panel, arena: std.mem.Allocator) !void {
        _ = arena;

        self.lock.lock();
        defer self.lock.unlock();

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

        // Row 1: User defined title.
        var title = try dvui.textLayout(@src(), .{}, .{ .expand = .horizontal, .font_style = .title_4 });
        try title.addText(self.modal_params.?.title, .{});
        title.deinit();

        // Row 2-?: User defined buttons
        const choices = self.modal_params.?.choiceItems();
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
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, all_panels: *_panels_.Panels, messenger: *_messenger_.Messenger, exit: ExitFn, window: *dvui.Window) !*Panel {
    var panel: *Panel = try allocator.create(Panel);
    panel.lock = try _lock_.init(allocator);
    errdefer {
        allocator.destroy(panel);
    }
    panel.allocator = allocator;
    panel.main_view = main_view;
    panel.all_panels = all_panels;
    panel.messenger = messenger;
    panel.exit = exit;
    panel.window = window;
    panel.modal_params = null;
    return panel;
}
