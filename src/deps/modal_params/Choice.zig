const std = @import("std");

const ChoiceItem = struct {
    allocator: std.mem.Allocator,
    label: []const u8,
    implementor: ?*anyopaque,
    context: ?*anyopaque,
    call_back: ?*const fn (implementor: ?*anyopaque, context: ?*anyopaque) anyerror!void,

    fn deinit(self: *ChoiceItem) void {
        self.allocator.free(self.label);
        self.allocator.destroy(self);
    }

    fn init(
        allocator: std.mem.Allocator,
        label: []const u8,
        implementor: ?*anyopaque,
        context: ?*anyopaque,
        call_back: ?*const fn (implementor: ?*anyopaque, context: ?*anyopaque) anyerror!void,
    ) !*const ChoiceItem {
        const self: *ChoiceItem = try allocator.create(ChoiceItem);
        self.label = try allocator.alloc(u8, label.len);
        @memcpy(@constCast(self.label), label);
        self.implementor = implementor;
        self.context = context;
        self.call_back = call_back;
        self.allocator = allocator;
        return self;
    }
};

/// Params is the parameters for the Choice modal screen's state.
/// See src/frontend/screen/modal/Choice/screen.zig setState.
/// Your arguments are the values assigned to each Params member.
/// For examples:
/// * See OK.zig for a Params example.
/// * See src/frontend/screen/modal/OK/screen.zig setState.
pub const Params = struct {
    allocator: std.mem.Allocator,

    // Parameters.
    title: []const u8,
    choices: []*const ChoiceItem,
    choices_index: usize,

    /// The caller owns the returned value.
    pub fn init(
        allocator: std.mem.Allocator,
        title: []const u8,
    ) !*Params {
        var args: *Params = try allocator.create(Params);
        args.title = try allocator.alloc(u8, title.len);
        @memcpy(@constCast(args.title), title);
        args.allocator = allocator;
        args.choices = try allocator.alloc(*ChoiceItem, 5);
        args.choices_index = 0;
        return args;
    }

    pub fn deinit(self: *Params) void {
        for (self.choices, 0..) |choice, i| {
            if (i == self.choices_index) {
                break;
            }
            @constCast(choice).deinit();
        }
        self.allocator.free(self.choices);
        self.allocator.destroy(self);
    }

    pub fn addChoiceItem(
        self: *Params,
        label: []const u8,
        implementor: ?*anyopaque,
        context: ?*anyopaque,
        call_back: ?*const fn (implementor: ?*anyopaque, context: ?*anyopaque) anyerror!void,
    ) !void {
        const choice_item: *const ChoiceItem = try ChoiceItem.init(
            self.allocator,
            label,
            implementor,
            context,
            call_back,
        );
        if (self.choices_index == self.choices.len) {
            const temps = self.choices;
            defer self.allocator.free(temps);
            self.choices = try self.allocator.alloc(*const ChoiceItem, temps.len + 5);
            for (temps, 0..) |temp, i| {
                self.choices[i] = temp;
            }
        }
        self.choices[self.choices_index] = choice_item;
        self.choices_index += 1;
    }

    pub fn choiceItems(self: *Params) []*const ChoiceItem {
        return self.choices[0..self.choices_index];
    }
};
