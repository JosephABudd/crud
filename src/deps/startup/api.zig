/// KICKZIG TODO: You are free to modify this file.
/// You may want to add your own members to these startup structs.
const std = @import("std");
const dvui = @import("dvui");

const _channel_ = @import("channel");
const _closedownjobs_ = @import("closedownjobs");
const _modal_params_ = @import("modal_params");
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const ScreenPointers = @import("screen_pointers").ScreenPointers;
const Store = @import("store").Store;

/// Backend is the parameters passed to the back-end when it is initialized.
pub const Backend = struct {
    allocator: std.mem.Allocator,
    send_channels: *_channel_.BackendToFrontend,
    receive_channels: *_channel_.FrontendToBackend,
    triggers: *_channel_.Trigger,
    close_down_jobs: *_closedownjobs_.Jobs,
    exit: ExitFn,

    store: ?*Store = null,
};

/// Frontend is the parameters passed to the front-end when it is initialized.
pub const Frontend = struct {
    allocator: std.mem.Allocator,
    window: *dvui.Window,
    send_channels: *_channel_.FrontendToBackend,
    receive_channels: *_channel_.BackendToFrontend,
    main_view: *MainView,
    close_down_jobs: *_closedownjobs_.Jobs,
    exit: ExitFn,
    screen_pointers: *ScreenPointers,

    pub fn setMainView(self: *const Frontend, main_view: *MainView) void {
        @constCast(self).main_view = main_view;
    }

    pub fn setScreenPointers(self: *const Frontend, screen_pointers: *ScreenPointers) void {
        @constCast(self).screen_pointers = screen_pointers;
    }
};
