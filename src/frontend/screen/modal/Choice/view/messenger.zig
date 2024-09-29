const std = @import("std");

const _channel_ = @import("channel");
const _message_ = @import("message");
const _modal_params_ = @import("modal_params");

const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const Panels = @import("../panels.zig").Panels;
const ScreenTags = @import("framers").ScreenTags;

pub const Messenger = struct {
    allocator: std.mem.Allocator,
    arena: std.mem.Allocator,

    main_view: *MainView,
    all_panels: *Panels,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,
    exit: ExitFn,

    pub fn init(allocator: std.mem.Allocator, main_view: *MainView, send_channels: *_channel_.FrontendToBackend, receive_channels: *_channel_.BackendToFrontend, exit: ExitFn) !*Messenger {
        var messenger: *Messenger = try allocator.create(Messenger);
        messenger.allocator = allocator;
        messenger.main_view = main_view;
        messenger.send_channels = send_channels;
        messenger.receive_channels = receive_channels;
        messenger.exit = exit;
    
        // For a messenger to receive a message, the messenger must:
        // 1. implement the behavior of the message's channel.
        // 2. subscribe to the message's channel.
    
        // Below is an example of the messenger adding the behavior requried to receive the AddContact message.
        // // The AddContact message.
        // // * Define the required behavior.
        // var addContactBehavior = try receive_channels.AddContact.initBehavior();
        // errdefer {
        //     allocator.destroy(messenger);
        // }
        // addContactBehavior.implementor = messenger;
        // addContactBehavior.receiveFn = Messenger.receiveAddContact;
        // // * Subscribe in order to receive the AddContact messages.
        // try receive_channels.AddContact.subscribe(addContactBehavior);
        // errdefer {
        //     allocator.destroy(messenger);
        // }
    
        return messenger;
    }

    pub fn deinit(self: *Messenger) void {
        self.allocator.destroy(self);
    }

    // Below is an example of a receive function.
    // // receiveAddContact is provided as an example.
    // // It receives the AddContact message.
    // // It implements a behavior required by receive_channels.AddContact.
    // pub fn receiveAddContact(implementor: *anyopaque, message: *_message_.AddContact.Message) anyerror!void {
    //     var self: *Messenger = @alignCast(@ptrCast(implementor));
    //     defer message.deinit();
    //     _ = self;
    // }
};
