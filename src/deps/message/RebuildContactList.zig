/// This file was generated by kickzig when you added the "RebuildContactList" message.
/// This file will be removed by kickzig if you remove the "RebuildContactList" message.
/// The "RebuildContactList" message is:
/// * sent from the back-end to the front-end only.
/// The back-end will:
/// 1. init this message.
/// 2. set the back-end payload.
/// 3. send the message to the front-end.
/// The front-end:
/// 1. will receive the message and process the data in the back-end payload.
/// 2. WILL NOT RETURN THE MESSAGE TO THE BACK-END.
const std = @import("std");
const Contact = @import("record").List;
const Counter = @import("counter").Counter;
const ScreenTags = @import("framers").ScreenTags;

// BackendPayload is the "RebuildContactList" message from the back-end to the front-end.
/// KICKZIG TODO: Add your own back-end payload fields and methods.
/// KICKZIG TODO: Customize pub const Settings for your fields.
/// KICKZIG TODO: Customize fn init(...), fn deinit(...) and pub fn set(...) for your fields.
pub const BackendPayload = struct {
    allocator: std.mem.Allocator = undefined,
    is_set: bool,

    contacts: ?[]const *const Contact,

    pub const Settings = struct {
        contacts: ?[]const *const Contact,
    };

    fn init(allocator: std.mem.Allocator) !*BackendPayload {
        var self: *BackendPayload = try allocator.create(BackendPayload);
        self.allocator = allocator;
        self.contacts = null;
        return self;
    }

    fn deinit(self: *BackendPayload) void {
        if (self.contacts) |contacts| {
            for (contacts) |contact| {
                contact.deinit();
            }
            self.allocator.free(contacts);
        }
        self.allocator.destroy(self);
    }

    // Returns an error if already set.
    pub fn set(self: *BackendPayload, values: Settings) !void {
        if (self.is_set) {
            return error.RebuildContactListBackendPayloadAlreadySet;
        }
        self.is_set = true;
        self.contacts = try self.copyOfContacts(values.contacts);
    }

    /// Returns a copy of the slice of contacts.
    pub fn copyContacts(self: *BackendPayload) !?[]const *const Contact {
        return self.copyOfContacts(self.contacts);
    }

    /// Returns a copy of the param src_contacts.
    fn copyOfContacts(self: *BackendPayload, src_contacts: ?[]const *const Contact) !?[]*const Contact {
        if (src_contacts) |contacts| {
            var dest_contacts: []*const Contact = try self.allocator.alloc(*const Contact, contacts.len);
            for (contacts, 0..) |contact, i| {
                dest_contacts[i] = contact.copy() catch |err| {
                    for (dest_contacts, 0..) |deinit_contact, j| {
                        if (j == i) {
                            break;
                        }
                        deinit_contact.deinit();
                    }
                    self.allocator.free(dest_contacts);
                    return err;
                };
            }
            return dest_contacts;
        } else {
            return null;
        }
    }
};

/// This is the "RebuildContactList" message.
pub const Message = struct {
    allocator: std.mem.Allocator,
    count_pointers: *Counter,
    backend_payload: *BackendPayload,

    /// init creates an original message.
    pub fn init(allocator: std.mem.Allocator) !*Message {
        var self: *Message = try allocator.create(Message);
        self.count_pointers = try Counter.init(allocator);
        errdefer {
            allocator.destroy(self);
        }
        self.backend_payload = try BackendPayload.init(allocator);
        errdefer {
            allocator.destroy(self);
            self.count_pointers.deinit();
        }
        _ = self.count_pointers.inc();
        self.allocator = allocator;
        return self;
    }

    // deinit does not deinit until self is the final pointer to Message.
    pub fn deinit(self: *Message) void {
        if (self.count_pointers.dec() > 0) {
            // There are more pointers.
            // See fn copy.
            return;
        }
        // This is the last existing pointer.
        self.count_pointers.deinit();
        self.allocator.destroy(self);
    }

    /// KICKZIG TODO:
    /// copy pretends to create and return a copy of the message.
    /// The dispatcher sends a copy to each receiveFn.
    /// Each receiveFn owns the message copy and must deinit it.
    ///
    /// In this case copy does not return a copy of itself.
    /// In order to save memory space, it really only
    /// * increments the count of the number of pointers to this message.
    /// * returns self.
    /// See deinit().
    pub fn copy(self: *Message) !*Message {
        _ = self.count_pointers.inc();
        return self;
    }
};
