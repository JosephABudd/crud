const std = @import("std");

const _channel_ = @import("channel");
const _modal_params_ = @import("modal_params");
const _panels_ = @import("../panels.zig");

const AddView = _panels_.Add.View;
const AddContactRecord = @import("record").Add;
const AddContactMessage = @import("message").AddContact;
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const OKModalParams = @import("modal_params").OK;
const PanelTags = _panels_.PanelTags;
const ScreenOptions = @import("../screen.zig").Options;
const ScreenTags = @import("framers").ScreenTags;
const Tab = @import("widget").Tab;
const Tabs = @import("widget").Tabs;

pub const Messenger = struct {
    allocator: std.mem.Allocator,

    tabs: *Tabs,
    main_view: *MainView,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,
    exit: ExitFn,
    screen_options: ScreenOptions,

    pub fn init(
        allocator: std.mem.Allocator,
        tabs: *Tabs,
        main_view: *MainView,
        send_channels: *_channel_.FrontendToBackend,
        receive_channels: *_channel_.BackendToFrontend,
        exit: ExitFn,
        screen_options: ScreenOptions,
    ) !*Messenger {
        var self: *Messenger = try allocator.create(Messenger);
        self.allocator = allocator;
        self.tabs = tabs;
        self.main_view = main_view;
        self.send_channels = send_channels;
        self.receive_channels = receive_channels;
        self.exit = exit;
        self.screen_options = screen_options;

        // The AddContact message.
        // * Define the required behavior.
        var add_contact_behavior = try receive_channels.AddContact.initBehavior();
        errdefer allocator.destroy(self);

        add_contact_behavior.implementor = self;
        add_contact_behavior.receiveFn = Messenger.receiveAddContact;
        // * Subscribe in order to receive the AddContact messages.
        try receive_channels.AddContact.subscribe(add_contact_behavior);
        errdefer allocator.destroy(self);

        return self;
    }

    pub fn deinit(self: *Messenger) void {
        self.allocator.destroy(self);
    }

    // AddContact messages.

    pub fn sendAddContact(self: *Messenger, contact: *AddContactRecord, add_tab: *anyopaque, add_view: *anyopaque) !void {
        std.log.info("sendAddContact: screen_name is {s}", .{self.screen_options.screen_name.?});
        var msg: *AddContactMessage = try AddContactMessage.init(self.allocator);
        try msg.frontend_payload.set(
            .{
                .contact = contact,
                .screen_tag = ScreenTags.Tabbar,
                .add_tab = add_tab,
                .add_view = add_view,
            },
        );
        errdefer msg.deinit();
        // send will deinit msg even if there is an error.
        try self.send_channels.AddContact.send(msg);
    }

    // receiveAddContact receives the AddContact message.
    // It implements a behavior required by receive_channels.AddContact.
    // Errors are handled and returned.
    pub fn receiveAddContact(implementor: *anyopaque, message: *AddContactMessage) anyerror!void {
        var self: *Messenger = @alignCast(@ptrCast(implementor));
        defer message.deinit();

        if (message.frontend_payload.screen_tag) |screen_tag| {
            if (screen_tag != ScreenTags.Tabbar) {
                // Not sent by this screen.
                return;
            }
        } else {
            // Not sent by this screen.
            return;
        }

        if (message.frontend_payload.add_tab) |payload_add_tab| {
            const tab_exists: bool = self.tabs.hasTab(payload_add_tab) catch |err| {
                self.exit(@src(), err, "self.tabs.hasTab(tab)");
                return err;
            };
            if (!tab_exists) {
                return;
            }
        } else {
            // Not sent by this screen.
            return;
        }

        // Sent by this screen from a tab that still exists.

        if (message.backend_payload.user_error_message) |user_error_message| {
            // The back-end is reporting a user error.
            // Inform the user.
            const ok_args = OKModalParams.init(self.allocator, "Error.", user_error_message) catch |err| {
                self.exit(@src(), err, "OKModalParams.init(self.allocator, \"Error.\", user_error_message)");
                return err;
            };
            self.main_view.showOK(ok_args);
            return;
        }
        // No user errors.

        // Clear the form.
        const add_view: *AddView = @alignCast(@ptrCast(message.frontend_payload.add_view.?));
        add_view.clearForm();
        // Inform the user.
        const ok_args = OKModalParams.init(self.allocator, "Success.", "The contact was added.") catch |err| {
            self.exit(@src(), err, "OKModalParams.init(self.allocator, \"Success.\", \"The contact was added.\")");
            return err;
        };
        self.main_view.showOK(ok_args);
    }
};
