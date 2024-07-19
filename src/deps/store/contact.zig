const std = @import("std");
const sqlite = @import("sqlite");
const Store = @import("api.zig").Store;
const Record = @import("record");

pub const Contact = struct {
    store: *Store,
    allocator: std.mem.Allocator,

    const create_statement: [:0]const u8 =
        \\ CREATE TABLE IF NOT EXISTS contacts(
        \\   id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\   name TEXT NOT NULL,
        \\   address TEXT NOT NULL,
        \\   city TEXT NOT NULL,
        \\   state TEXT NOT NULL,
        \\   zip TEXT NOT NULL
        \\ );
    ;

    const get_all_statement: [:0]const u8 =
        \\ SELECT id, name, address, city, state, zip
        \\ FROM contacts;
    ;

    const get_statement: [:0]const u8 =
        \\ SELECT id, name, address, city, state, zip
        \\ FROM contacts
        \\ WHERE id == ?;
    ;

    const get_last_inserted_statement: [:0]const u8 =
        \\ SELECT id, name, address, city, state, zip
        \\ FROM contacts
        \\ WHERE id = last_insert_rowid();
    ;

    const add_statement: [:0]const u8 =
        \\ INSERT INTO contacts(name, address, city, state, zip)
        \\ VALUES (?, ?, ?, ?, ?);
    ;
    const update_statement: [:0]const u8 =
        \\ UPDATE contacts
        \\ SET
        \\   name = ?,
        \\   address = ?,
        \\   city = ?,
        \\   state = ?,
        \\   zip = ?
        \\ WHERE id = ?;
    ;

    const delete_statement: [:0]const u8 =
        \\ DELETE FROM contacts
        \\ WHERE id = ?;
    ;

    pub fn init(store: *Store) !*Contact {
        var self: *Contact = try store.allocator.create(Contact);
        self.allocator = store.allocator;
        self.store = store;

        // Create the table.
        var statement = try self.store.db.prepare(create_statement);
        defer statement.deinit();
        try statement.exec();
        errdefer {
            self.allocator.destroy(self);
        }

        return self;
    }

    pub fn deinit(self: *Contact) void {
        self.allocator.destroy(self);
    }

    pub fn add(self: *Contact, name: []const u8, address: []const u8, city: []const u8, state: []const u8, zip: []const u8) !void {
        var statement = try self.store.db.prepare(add_statement);
        defer statement.deinit();

        try statement.bind(0, name);
        try statement.bind(1, address);
        try statement.bind(2, city);
        try statement.bind(3, state);
        try statement.bind(4, zip);

        try statement.exec();
    }

    pub fn update(self: *Contact, id: i64, name: []const u8, address: []const u8, city: []const u8, state: []const u8, zip: []const u8) !void {
        var statement = try self.store.db.prepare(update_statement);
        defer statement.deinit();

        try statement.bind(0, name);
        try statement.bind(1, address);
        try statement.bind(2, city);
        try statement.bind(3, state);
        try statement.bind(4, zip);
        try statement.bind(5, id);

        try statement.exec();
    }

    // The caller owns the returned value;
    pub fn getAll(self: *Contact) !?[]*const Record.List {
        var statement: sqlite.Statement = try self.store.db.prepare(get_all_statement);
        defer statement.deinit();

        var rows = std.ArrayList(*const Record.List).init(self.allocator);
        defer rows.deinit();

        while (true) {
            switch (try statement.step()) {
                .row => {
                    // Construct the list record from the row.
                    const list: *const Record.List = try self.statementToListRecord(&statement);
                    errdefer {
                        while (rows.popOrNull()) |row| {
                            row.deinit();
                        }
                        rows.deinit();
                    }
                    // Add the list record.
                    try rows.append(list);
                    errdefer {
                        while (rows.popOrNull()) |row| {
                            row.deinit();
                        }
                        rows.deinit();
                    }
                },
                .done => {
                    const records = try rows.toOwnedSlice();
                    if (records.len > 0) {
                        return records;
                    }
                    // No records.
                    self.allocator.free(records);
                    return null;
                },
            }
        }
        // No records.
        return null;
    }

    pub fn remove(self: *Contact, id: i64) !void {
        var statement = try self.store.db.prepare(delete_statement);
        defer statement.deinit();

        try statement.bind(0, id);

        try statement.exec();
    }

    fn statementToListRecord(self: *Contact, statement: *sqlite.Statement) !*const Record.List {
        // Read each column.
        const id = try statement.column(i64, 0);
        const name = try statement.column([]const u8, 1);
        const address = try statement.column([]const u8, 2);
        errdefer {
            self.allocator.free(name);
        }
        const city = try statement.column([]const u8, 3);
        errdefer {
            self.allocator.free(name);
            self.allocator.free(address);
        }
        const state = try statement.column([]const u8, 4);
        errdefer {
            self.allocator.free(name);
            self.allocator.free(address);
            self.allocator.free(city);
        }
        const zip = try statement.column([]const u8, 5);
        errdefer {
            self.allocator.free(name);
            self.allocator.free(address);
            self.allocator.free(city);
            self.allocator.free(state);
        }

        // Construct the list record.
        const list: *const Record.List = try Record.List.init(
            self.allocator,
            id,
            name,
            address,
            city,
            state,
            zip,
        );
        errdefer {
            self.allocator.free(name);
            self.allocator.free(address);
            self.allocator.free(city);
            self.allocator.free(state);
            self.allocator.free(zip);
        }

        // Return the list record.
        return list;
    }
};
