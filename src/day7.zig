const std = @import("std");
const parseInt = std.fmt.parseInt;

fn total_calibration_result(input: []const u8) usize {
    var it_line = std.mem.splitScalar(u8, input, '\n');
    var calibration: usize = 0;
    while (it_line.next()) |line| {
        calibration += calc_line(line);
    }
    return calibration;
}

fn calc_line(input: []const u8) usize {
    var it_line = std.mem.tokenizeAny(u8, input, ": ");
    const first = it_line.next() orelse "0";
    const expected = parseInt(usize, first, 10) catch @panic("unable to parseInt");
    var i: usize = 0;
    var operands: [20]usize = .{0} ** 20;
    while (it_line.next()) |operand| : (i += 1) {
        operands[i] = parseInt(usize, operand, 10) catch @panic("unable to parseInt");
    }
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
    try std.testing.expectEqual(3749, total_calibration_result(input));
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
    var buf: [20000]u8 = undefined;
    const read = try in_stream.readAll(&buf);
    std.debug.print("read {d}\n", .{read});

    const result = total_calibration_result(buf[0..read]);
    try stdout.print("Result: {d}\n", .{result});
    try bw.flush();
}
