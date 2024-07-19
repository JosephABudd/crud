const std = @import("std");
const Edit = @import("edit.zig").Contact;
const Remove = @import("remove.zig").Contact;
const Counter = @import("counter").Counter;

/// Contact is a record that is displayed for selection.
pub const Contact = struct {
    allocator: std.mem.Allocator,
    count_pointers: *Counter,
    id: i64,
    name: ?[]const u8,
    address: ?[]const u8,
    city: ?[]const u8,
    state: ?[]const u8,
    zip: ?[]const u8,

    pub fn init(allocator: std.mem.Allocator, id: ?i64, name: ?[]const u8, address: ?[]const u8, city: ?[]const u8, state: ?[]const u8, zip: ?[]const u8) !*Contact {
        var self: *Contact = try allocator.create(Contact);
        self.allocator = allocator;
        self.count_pointers = try Counter.init(allocator);
        errdefer allocator.destroy(self);
        _ = self.count_pointers.inc();
        // ID.
        if (id) |param_id| {
            self.id = param_id;
        } else {
            allocator.destroy(self);
            return error.ContactIsMissingID;
        }
        // Name.
        if (name) |param_name| {
            self.name = try allocator.alloc(u8, param_name.len);
            errdefer self.deinit();
            @memcpy(@constCast(self.name.?), param_name);
        } else {
            self.name = null;
        }
        // Address.
        if (address) |param_address| {
            self.address = try allocator.alloc(u8, param_address.len);
            errdefer self.deinit();
            @memcpy(@constCast(self.address.?), param_address);
        } else {
            self.address = null;
        }
        // City.
        if (city) |param_city| {
            self.city = try allocator.alloc(u8, param_city.len);
            errdefer self.deinit();
            @memcpy(@constCast(self.city.?), param_city);
        } else {
            self.city = null;
        }
        // State.
        if (state) |param_state| {
            self.state = try allocator.alloc(u8, param_state.len);
            errdefer self.deinit();
            @memcpy(@constCast(self.state.?), param_state);
        } else {
            self.state = null;
        }
        // Zip.
        if (zip) |param_zip| {
            self.zip = try allocator.alloc(u8, param_zip.len);
            errdefer self.deinit();
            @memcpy(@constCast(self.zip.?), param_zip);
        } else {
            self.zip = null;
        }

        return self;
    }

    pub fn deinit(self: anytype) void {
        return switch (@TypeOf(self)) {
            *Contact => _deinit(self),
            *const Contact => _deinit(@constCast(self)),
            else => {},
        };
    }

    fn _deinit(self: *Contact) void {
        if (self.count_pointers.dec() > 0) {
            // There are more pointers.
            // See fn copy.
            return;
        }
        // This is the last existing pointer.
        self.count_pointers.deinit();
        if (self.name) |name| {
            self.allocator.free(name);
        }
        if (self.address) |address| {
            self.allocator.free(address);
        }
        if (self.city) |city| {
            self.allocator.free(city);
        }
        if (self.state) |state| {
            self.allocator.free(state);
        }
        if (self.zip) |zip| {
            self.allocator.free(zip);
        }
        self.allocator.destroy(self);
    }

    /// KICKZIG TODO:
    /// copy pretends to create and return a copy of the message.
    /// Always pass a copy to a fn. The fn must deinit its copy.
    ///
    /// In this case copy does not return a copy of itself.
    /// In order to save memory space, it really only
    /// * increments the count of the number of pointers to this message.
    /// * returns self.
    /// See deinit().
    pub fn copy(self: *const Contact) !*const Contact {
        _ = self.count_pointers.inc();
        return self;
    }
};

pub const Slice = struct {
    allocator: std.mem.Allocator,
    slice: []*const Contact,
    index: usize,
    slice_was_given_away: bool,

    pub fn init(allocator: std.mem.Allocator) !*Slice {
        var self: *Slice = try allocator.create(Slice);
        self.slice = try allocator.alloc(*Contact, 10);
        errdefer {
            allocator.destroy(self);
        }
        self.index = 0;
        self.slice_was_given_away = false;
        return self;
    }

    pub fn deinit(self: *Slice) void {
        if (self.index > 0 and !self.slice_was_given_away) {
            // The slice has not been given away so destroy each item.
            const deinit_contacts: []const *const Contact = self.slice[0..self.index];
            for (deinit_contacts) |deinit_contact| {
                deinit_contact.deinit();
            }
        }
        // Free the slice.
        self.allocator.free(self.slice);
        self.allocator.destroy(self);
    }

    // The caller owns the slice.
    pub fn sliced(self: *Slice) !?[]const *const Contact {
        if (self.index == 0) {
            return null;
        }
        if (self.slice_was_given_away) {
            return error.ContactListSliceAlreadyGivenAway;
        }
        self.slice_was_given_away = true;
        var contacts_copy: []*const Contact = try self.allocator.alloc(*const Contact, self.index);
        for (self.slice, 0..self.index) |contact, i| {
            // if (i == self.index) {
            //     break;
            // }
            contacts_copy[i] = contact;
        }
        return contacts_copy;
    }

    // append copies contact.
    pub fn append(self: *Slice, contact: *const Contact) !void {
        if (self.slice_was_given_away) {
            return error.SliceAlreadyGivenAway;
        }
        // Copy the contact record.
        var contact_copy: *Contact = try Contact.init(
            contact.allocator,
            contact.id,
            contact.name,
            contact.address,
            contact.city,
            contact.state,
            contact.zip,
        );
        if (self.index == self.slice.len) {
            // Make a new bigger slice.
            const temp_contacts: []*const Contact = self.slice;
            self.slice = try self.allocator.alloc(*const Contact, (self.slice.len + 5));
            errdefer {
                contact_copy.deint();
            }
            for (temp_contacts, 0..) |temp_contact, i| {
                self.slice[i] = temp_contact;
            }
            self.allocator.free(temp_contacts);
        }
        self.slice[self.index] = contact_copy;
        self.index += 1;
    }
};
