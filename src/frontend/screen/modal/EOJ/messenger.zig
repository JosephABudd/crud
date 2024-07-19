    const std = @import("std");

const _channel_ = @import("channel");
const _closedownjobs_ = @import("closedownjobs");
const _message_ = @import("message");
const _modal_params_ = @import("modal_params");
const _panels_ = @import("panels.zig");
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;

pub const Messenger = struct {
    allocator: std.mem.Allocator,

    main_view: *MainView,
    all_panels: *_panels_.Panels,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,
    exit: ExitFn,

    pub fn deinit(self: *Messenger) void {
        self.allocator.destroy(self);
    }

    pub fn sendCloseDownJobs(self: *Messenger, jobs: ?[]const *const _closedownjobs_.Job) void {
        var message: *_message_.CloseDownJobs.Message = _message_.CloseDownJobs.init(self.allocator) catch {
            // ignore error.
            return;
        };
        message.frontend_payload.set(.{ .jobs = jobs }) catch {
            // ignore error.
            message.deinit();
            return;
        };
        self.send_channels.CloseDownJobs.send(message) catch {
            // ignore error.
            return;
        };
    }

    // receiveCloseDownJobs receives the CloseDownJobs message from the back-end.
    // It passes the information to the EOJ panel.
    pub fn receiveCloseDownJobs(implementor: *anyopaque, message: *_message_.CloseDownJobs.Message) anyerror!void {
        defer message.deinit();

        var self: *Messenger = @alignCast(@ptrCast(implementor));
        self.all_panels.EOJ.?.update(message.backend_payload.status_update, message.backend_payload.completed, message.backend_payload.progress);
    }
};

pub fn init(allocator: std.mem.Allocator, main_view: *MainView, send_channels: *_channel_.FrontendToBackend, receive_channels: *_channel_.BackendToFrontend, exit: ExitFn) !*Messenger {
    var messenger: *Messenger = try allocator.create(Messenger);
    messenger.allocator = allocator;
    messenger.main_view = main_view;
    messenger.send_channels = send_channels;
    messenger.receive_channels = receive_channels;
    messenger.exit = exit;

    // The CloseDownJobs message.
    // * Define the required behavior.
    var closeDownJobsBehavior = try receive_channels.CloseDownJobs.initBehavior();
    errdefer {
        allocator.destroy(messenger);
    }
    closeDownJobsBehavior.implementor = messenger;
    closeDownJobsBehavior.receiveFn = Messenger.receiveCloseDownJobs;
    // * Subscribe in order to receive the CloseDownJobs messages.
    try receive_channels.CloseDownJobs.subscribe(closeDownJobsBehavior);
    errdefer {
        allocator.destroy(messenger);
    }

    return messenger;
}