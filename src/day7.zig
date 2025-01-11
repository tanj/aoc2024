const std = @import("std");
const parseInt = std.fmt.parseInt;

fn total_calibration_result(allocator: std.mem.Allocator, input: []const u8) !usize {
    var it_line = std.mem.splitScalar(u8, input, '\n');
    var calibration: usize = 0;
    while (it_line.next()) |line| {
        calibration += try calc_line(allocator, line);
    }
    return calibration;
}

fn calc_line(allocator: std.mem.Allocator, input: []const u8) !usize {
    var it_line = std.mem.tokenizeAny(u8, input, ": ");
    const first = it_line.next() orelse "0";
    const expected = parseInt(usize, first, 10) catch @panic("unable to parseInt");
    var i: usize = 0;
    var prev = try std.ArrayList(usize).initCapacity(allocator, 2 ^ 8);
    defer prev.deinit();
    var cur = try std.ArrayList(usize).initCapacity(allocator, 2 ^ 8);
    defer cur.deinit();
    while (it_line.next()) |operand| : (i += 1) {
        try cur.resize(0);
        const item = try parseInt(usize, operand, 10);
        if (prev.items.len == 0) {
            try prev.append(item);
        } else {
            for (prev.items) |x| {
                if (x <= expected) {
                    try cur.append(x + item);
                    try cur.append(x * item);
                }
            }
            try prev.resize(0);
            try prev.appendSlice(cur.items);
        }
    }
    for (cur.items) |x| {
        if (x == expected) {
            return expected;
        }
    }
    // std.debug.print("{s}\n", .{input});
    return 0;
}

test "day 7 part 1" {
    const input: []const u8 =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;
    // std.debug.print("{s}\n", .{input});
    try std.testing.expectEqual(3749, try total_calibration_result(std.testing.allocator, input));
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const input: std.fs.File = try std.fs.cwd().openFile("src/input7.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [30000]u8 = undefined;
    const read = try in_stream.readAll(&buf);
    std.debug.print("read {d}\n", .{read});

    const result = try total_calibration_result(arena.allocator(), buf[0..read]);
    try stdout.print("Result: {d}\n", .{result});
    try bw.flush();
}
