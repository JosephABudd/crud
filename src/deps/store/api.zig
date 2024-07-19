const std = @import("std");
const sqlite = @import("sqlite");
const Contact = @import("contact.zig").Contact;

pub const Store = struct {
    allocator: std.mem.Allocator,
    db: sqlite.SQLite3,
    contact_table: *Contact,

    /// init creates, opens the store and creates the tables.
    /// Returns the store or error.
    pub fn init(allocator: std.mem.Allocator, store_path: [:0]const u8) !*Store {
        var self: *Store = try allocator.create(Store);
        self.allocator = allocator;
        self.db = try sqlite.SQLite3.open(store_path);
        errdefer {
            allocator.destroy(self);
        }
        self.contact_table = try Contact.init(self);
        errdefer {
            self.db.deinit();
            allocator.destroy(self);
        }
        return self;
    }

    pub fn deinit(self: *Store) void {
        self.contact_table.deinit();
        self.db.close();
        self.allocator.destroy(self);
    }

    // pub fn printSqliteErrMsg(self: *Store) void {
    //     std.log.warn("sqlite3 errmsg: {s}\n", .{self.db.errmsg()});
    // }
};
