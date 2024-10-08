// This file is re-generated by kickzig when a message is added or removed.
// DO NOT EDIT THIS FILE.
const std = @import("std");

const BackToFrontDispatcher = @import("backtofront/general_dispatcher.zig").GeneralDispatcher;
const FrontToBackDispatcher = @import("fronttoback/general_dispatcher.zig").GeneralDispatcher;
const ExitFn = @import("various").ExitFn;

const BF_EditContact = @import("backtofront/EditContact.zig").Group;
const BF_RebuildContactList = @import("backtofront/RebuildContactList.zig").Group;
const BF_RemoveContact = @import("backtofront/RemoveContact.zig").Group;
const BF_AddContact = @import("backtofront/AddContact.zig").Group;
const FB_EditContact = @import("fronttoback/EditContact.zig").Group;
const FB_RemoveContact = @import("fronttoback/RemoveContact.zig").Group;
const FB_AddContact = @import("fronttoback/AddContact.zig").Group;
const TR_RebuildContactList = @import("trigger/RebuildContactList.zig").Group;

/// FrontendToBackend is each message's channel.
pub const FrontendToBackend = struct {
    allocator: std.mem.Allocator,
    // Dispatcher.
    general_dispatcher: *FrontToBackDispatcher,

    // Channels.
    EditContact: *FB_EditContact,
    RemoveContact: *FB_RemoveContact,
    AddContact: *FB_AddContact,

    pub fn deinit(self: *FrontendToBackend) void {
        self.general_dispatcher.deinit();
        self.allocator.destroy(self);
    }

    pub fn init(allocator: std.mem.Allocator, exit: ExitFn) !*FrontendToBackend {
        var self: *FrontendToBackend = try allocator.create(FrontendToBackend);
        self.allocator = allocator;
        self.general_dispatcher = try FrontToBackDispatcher.init(allocator, exit);
        self.EditContact = self.general_dispatcher.EditContact.?;
        self.RemoveContact = self.general_dispatcher.RemoveContact.?;
        self.AddContact = self.general_dispatcher.AddContact.?;

        return self;
    }
};


/// BackendToFrontend is each message's channel.
pub const BackendToFrontend = struct {
    allocator: std.mem.Allocator,
    // Dispatcher.
    general_dispatcher: *BackToFrontDispatcher,
    // Channels.
    EditContact: *BF_EditContact,
    RebuildContactList: *BF_RebuildContactList,
    RemoveContact: *BF_RemoveContact,
    AddContact: *BF_AddContact,

    pub fn deinit(self: *BackendToFrontend) void {
        self.general_dispatcher.deinit();
        self.allocator.destroy(self);
    }

    pub fn init(allocator: std.mem.Allocator, exit: ExitFn) !*BackendToFrontend {
        var self: *BackendToFrontend = try allocator.create(BackendToFrontend);
        self.allocator = allocator;
        // Dispatcher.
        self.general_dispatcher = try BackToFrontDispatcher.init(allocator, exit);
        // Channels.
        self.EditContact = self.general_dispatcher.EditContact.?;
        self.RebuildContactList = self.general_dispatcher.RebuildContactList.?;
        self.RemoveContact = self.general_dispatcher.RemoveContact.?;
        self.AddContact = self.general_dispatcher.AddContact.?;

        return self;
    }
};

/// Trigger is each trigger.
pub const Trigger = struct {
    allocator: std.mem.Allocator,
    RebuildContactList: ?*TR_RebuildContactList = null,

    pub fn deinit(self: *Trigger) void {
        if (self.RebuildContactList) |RebuildContactList| {
            RebuildContactList.deinit();
        }
        self.allocator.destroy(self);
    }
    pub fn init(allocator: std.mem.Allocator, exit: ExitFn) !*Trigger {
        var self: *Trigger = try allocator.create(Trigger);
        self.allocator = allocator;
    
        self.RebuildContactList = try TR_RebuildContactList.init(self.allocator, exit);
        errdefer self.deinit();

        return self;
    }
};

