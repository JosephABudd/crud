/// This is the back-end's API.
/// This file was generated by kickzig when you created the framework.
/// This file will be never be touched by kickzig.
/// You are free to edit this file.
const std = @import("std");
const _channel_ = @import("channel");
const _messenger_ = @import("messenger/api.zig");
const _startup_ = @import("startup");

var messenger: ?*_messenger_.Messenger = null;
var triggers: *_channel_.Trigger = undefined;

/// KICKZIG TODO:
/// kickStart the backend.
/// Trigger messengers to send their startup messages to the front-end.
pub fn kickStart() !void {
    // Build the contact list.
    return triggers.RebuildContactList.?.trigger();
}

pub fn init(startup: _startup_.Backend) !void {
    messenger = try _messenger_.init(startup);
    triggers = startup.triggers;
}

pub fn deinit() void {
    if (messenger) |msngr| {
        msngr.deinit();
    }
}
