const std = @import("std");
const dvui = @import("dvui");

const _lock_ = @import("lock");
const _jobs_ = @import("closedownjobs");
const ExitFn = @import("various").ExitFn;
const MainView = @import("framers").MainView;
const Params = @import("modal_params").EOJ;

const Context = enum {
    none,
    started,
    completed,
    waiting,
    forced,
};

var _allocator: std.mem.Allocator = undefined;
var lock: *_lock_.ThreadLock = undefined;
var _main_view: *MainView = undefined;
var state: Context = .none;
var modal_params: ?*Params = null;
var window: *dvui.Window = undefined;
var source_location: ?std.builtin.SourceLocation = null;
var source_error: anyerror = undefined;

pub fn eoj() void {
    lock.lock();
    defer lock.unlock();

    state = .completed;
    dvui.refresh(window, @src(), null);
}

pub fn init(allocator: std.mem.Allocator, jobs: *_jobs_.Jobs, win: *dvui.Window) !ExitFn {
    lock = try _lock_.init(allocator);
    _allocator = allocator;
    _main_view = undefined;
    modal_params = try Params.init(allocator, jobs);
    window = win;
    return &exit;
}

pub fn set_screens(main_view: *MainView) void {
    _main_view = main_view;
}

pub fn deinit() void {
    lock.deinit();
    if (modal_params) |params| {
        params.deinit();
    }
}

fn exit(src: std.builtin.SourceLocation, err: anyerror, description: []const u8) void {
    lock.lock();
    defer lock.unlock();

    if (state != .none) {
        return;
    }

    source_location = src;
    source_error = err;

    modal_params.?.is_fatal = true;
    modal_params.?.setHeading("Closing. Fatal Error.");
    modal_params.?.setMessage(description);
    state = .started;
    log_close();
}

// close attempts to close.
// if ok_to_force == false:
//  * waits if a modal is open.
//  * closes if a modal is not open.
// if ok_to_force == true:
//  * forces the close on next frame.
pub fn close(user_message: []const u8, ok_to_force: bool) void {
    lock.lock();
    defer lock.unlock();

    if (state != .none) {
        return;
    }

    modal_params.?.is_fatal = false;
    modal_params.?.setHeading("Closing");
    modal_params.?.setMessage(user_message);

    if (_main_view.isModal()) {
        if (ok_to_force) {
            // Force this modal screen to close.
            state = .forced;
            dvui.refresh(window, @src(), null);
            return;
        } else {
            // Wait for this modal screen to close.
            state = .waiting;
            return;
        }
    }
    log_close();
}

// waiting closes when the modal is closed.
pub fn waiting() void {
    lock.lock();
    defer lock.unlock();

    if (state != .waiting) {
        return;
    }

    if (!_main_view.isModal()) {
        state = .started;
        log_close();
    }
}

// forced changes state to .started forcing the closing process.
pub fn forced() void {
    lock.lock();
    defer lock.unlock();

    if (state != .forced) {
        return;
    }

    state = .started;
    log_force_close();
}

// log the error and begin the closing process.
// A modal screen is not currently displayed.
fn log_close() void {
    // Log the error.
    if (source_location) |src| {
        std.log.debug("{s}:{d}:{d}: {s}: {s}", .{ src.file, src.line, src.column, @errorName(source_error), modal_params.?.message.? });
    }

    _ = _main_view.showEOJ(modal_params.?);
    // The modal params are always owned by the modal screen.
    modal_params = null;
}

// log the error and force the closing process to begin.
// If there is a modal screen shown it will be replaced with the EOJ screen.
fn log_force_close() void {
    // Log the error.
    if (source_location) |src| {
        std.log.debug("{s}:{d}:{d}: {s}: {s}", .{ src.file, src.line, src.column, @errorName(source_error), modal_params.?.message.? });
    }

    _ = _main_view.forceEOJ(modal_params.?);
    // The modal params are always owned by the modal screen.
    modal_params = null;
}

pub fn context() Context {
    lock.lock();
    defer lock.unlock();
    return state;
}