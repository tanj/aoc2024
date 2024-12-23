const std = @import("std");
const parseInt = std.fmt.parseInt;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const input: std.fs.File = try std.fs.cwd().openFile("src/input5.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var print_queue = PrintQueue.init(arena.allocator());
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try print_queue.parse_line(line);
    }
    try stdout.print("Part 1: {d}\n", .{print_queue.process_part1()});
    try stdout.print("Part 2: {d}\n", .{print_queue.process_part2()});
    try bw.flush();
}

const Rule = struct {
    before: u8,
    after: u8,
};

fn parse_rule(line: []const u8) !Rule {
    var it_tok = std.mem.tokenizeScalar(u8, line, '|');
    var rule: Rule = undefined;
    if (it_tok.next()) |token| {
        rule.before = parseInt(u8, token, 10) catch 0;
    }
    if (it_tok.next()) |token| {
        rule.after = parseInt(u8, token, 10) catch 0;
    }
    return rule;
}

fn parse_pages(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    var pages = std.ArrayList(u8).init(allocator);
    var it_tok = std.mem.tokenizeScalar(u8, line, ',');
    while (it_tok.next()) |token| {
        const val = parseInt(u8, token, 10) catch 0;
        try pages.append(val);
    }
    return try pages.toOwnedSlice();
}

const PrintQueue = struct {
    allocator: std.mem.Allocator,
    rules: std.ArrayList(Rule),
    collected_rules: std.AutoHashMap(u8, std.ArrayList(u8)),
    pages_to_update: std.ArrayList([]u8),
    parsing_rules: bool = true,

    fn init(allocator: std.mem.Allocator) PrintQueue {
        const rules = std.ArrayList(Rule).init(allocator);
        const collected_rules = std.AutoHashMap(u8, std.ArrayList(u8)).init(allocator);
        const pages_to_update = std.ArrayList([]u8).init(allocator);
        return PrintQueue{
            .allocator = allocator,
            .rules = rules,
            .collected_rules = collected_rules,
            .pages_to_update = pages_to_update,
        };
    }

    fn deinit(self: *PrintQueue) void {
        self.rules.deinit();
        for (self.pages_to_update.items) |pages| {
            self.allocator.free(pages);
        }
        self.pages_to_update.deinit();
        var it = self.collected_rules.valueIterator();
        while (it.next()) |rule_list| {
            rule_list.deinit();
        }
        self.collected_rules.deinit();
    }

    fn parse_line(self: *PrintQueue, line: []const u8) !void {
        if (line.len > 0) {
            if (self.parsing_rules) {
                const rule = try parse_rule(line);
                try self.rules.append(rule);
                if (self.collected_rules.contains(rule.before)) {
                    const rule_list = self.collected_rules.getPtr(rule.before).?;
                    try rule_list.append(rule.after);
                } else {
                    var rule_list = std.ArrayList(u8).init(self.allocator);
                    try rule_list.append(rule.after);
                    try self.collected_rules.put(rule.before, rule_list);
                }
            } else {
                const pages = try parse_pages(self.allocator, line);
                try self.pages_to_update.append(pages);
            }
        } else {
            self.parsing_rules = false;
        }
    }

    fn validate_pages(self: *PrintQueue, pages: []u8) bool {
        for (pages, 0..pages.len) |page, i| {
            const before = self.collected_rules.getKey(page) orelse continue;
            const rules = self.collected_rules.get(before).?;
            for (pages[0..i]) |preceeding| {
                for (rules.items) |after| {
                    if (after == preceeding) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    fn process_part1(self: *PrintQueue) u64 {
        var middle_sum: u64 = 0;
        for (self.pages_to_update.items) |job| {
            if (self.validate_pages(job)) {
                middle_sum += mid(job);
            }
        }
        return middle_sum;
    }

    fn process_part2(self: *PrintQueue) u64 {
        var middle_sum: u64 = 0;
        for (self.pages_to_update.items) |job| {
            if (!self.validate_pages(job)) {
                var B = std.ArrayList(u8).init(self.allocator);
                B.appendNTimes(0, job.len) catch @panic("unable to alloc");
                std.mem.sort(u8, job, &self, struct {
                    fn inner(pq: *const *PrintQueue, a: u8, b: u8) bool {
                        return (pq.*).rule_sort(a, b);
                    }
                }.inner);
                middle_sum += mid(job);
                B.deinit();
            }
        }
        return middle_sum;
    }

    /// A lessThan function to use with sort applying the rules
    fn rule_sort(self: *PrintQueue, lhs: u8, rhs: u8) bool {
        const before = self.collected_rules.getKey(lhs) orelse return false;
        const is_less_than = self.collected_rules.get(before).?;
        for (is_less_than.items) |after| {
            if (rhs == after) {
                return true;
            }
        }
        return false;
    }
};

fn mid(slice: []u8) u8 {
    if (slice.len == 1) {
        return slice[0];
    }
    if (slice.len % 2 == 0) {
        const ix: usize = slice.len / 2;
        return (slice[ix] + slice[ix - 1]) / 2;
    }
    const ix: usize = (slice.len - 1) / 2;
    return slice[ix];
}

test "parse_line" {
    const alloc = std.testing.allocator;
    const input: []const u8 =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
        \\
    ;
    var print_queue = PrintQueue.init(alloc);
    defer print_queue.deinit();
    var line_tok = std.mem.splitScalar(u8, input, '\n');
    while (line_tok.next()) |line| {
        try print_queue.parse_line(line);
    }
    // std.debug.print("{any}\n", .{print_queue.rules.items});
    // std.debug.print("{any}\n", .{print_queue.pages_to_update.items});
    try std.testing.expectEqual(21, print_queue.rules.items.len);
    try std.testing.expectEqual(6, print_queue.pages_to_update.items.len);
    try std.testing.expect(print_queue.validate_pages(print_queue.pages_to_update.items[0]));
    try std.testing.expect(print_queue.validate_pages(print_queue.pages_to_update.items[1]));
    try std.testing.expect(print_queue.validate_pages(print_queue.pages_to_update.items[2]));
    try std.testing.expect(!print_queue.validate_pages(print_queue.pages_to_update.items[3]));
    try std.testing.expect(!print_queue.validate_pages(print_queue.pages_to_update.items[4]));
    try std.testing.expect(!print_queue.validate_pages(print_queue.pages_to_update.items[5]));
    try std.testing.expectEqual(143, print_queue.process_part1());
    try std.testing.expectEqual(123, print_queue.process_part2());
    var it = print_queue.collected_rules.iterator();
    while (it.next()) |entry| {
        std.debug.print("{any}: {any}\n", .{ entry.key_ptr.*, entry.value_ptr.items });
    }
}
