const std = @import("std");
const Store = @import("store").Contact;
const List = @import("list.zig");
const Counter = @import("counter").Counter;

/// Contact is a contact that the user added and submitted.
pub const Contact = struct {
    allocator: std.mem.Allocator,
    count_pointers: *Counter,
    name: ?[]const u8,
    address: ?[]const u8,
    city: ?[]const u8,
    state: ?[]const u8,
    zip: ?[]const u8,

    pub fn init(allocator: std.mem.Allocator, name: ?[]const u8, address: ?[]const u8, city: ?[]const u8, state: ?[]const u8, zip: ?[]const u8) !*Contact {
        var self: *Contact = try allocator.create(Contact);
        self.allocator = allocator;
        self.count_pointers = try Counter.init(allocator);
        errdefer allocator.destroy(self);
        _ = self.count_pointers.inc();
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
    pub fn copy(self: *Contact) !*Contact {
        _ = self.count_pointers.inc();
        return self;
    }
};
