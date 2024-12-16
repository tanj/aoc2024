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

    const input: std.fs.File = try std.fs.cwd().openFile("src/input2.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var safe: u64 = 0;
    var damp: u64 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            const report = try parse_line(arena.allocator(), line);
            if (status(report) == .Safe) {
                safe += 1;
            }
            if (try status_dampen(arena.allocator(), report) == .Safe) {
                damp += 1;
            }
        }
    }
    try stdout.print("Safe Reports: {d}\n", .{safe});
    try stdout.print("Damp Reports: {d}\n", .{damp});
    try bw.flush();
}

fn parse_line(allocator: std.mem.Allocator, line: []const u8) ![]i64 {
    var levels = std.ArrayList(i64).init(allocator);
    var it_tok = std.mem.tokenizeScalar(u8, line, ' ');
    while (it_tok.next()) |token| {
        const val = parseInt(i64, token, 10) catch 0;
        try levels.append(val);
    }
    return try levels.toOwnedSlice();
}

fn status(report: []i64) Status {
    std.debug.assert(report.len > 1);
    var prev: i64 = report[0];
    const dir = prev - report[1];
    for (report[1..]) |r| {
        const dir_diff = prev - r;
        const diff = @abs(dir_diff);
        prev = r;
        if (diff > 3 or diff < 1 or (dir < 0 and dir_diff > 0) or (dir > 0 and dir_diff < 0)) {
            return .Unsafe;
        }
    }
    return .Safe;
}

fn status_dampen(allocator: std.mem.Allocator, report: []i64) !Status {
    var s = status(report);
    if (s == .Safe) {
        return s;
    }
    for (0..report.len) |i| {
        var levels = std.ArrayList(i64).init(allocator);
        try levels.appendSlice(report);
        _ = levels.orderedRemove(i);
        const sl = try levels.toOwnedSlice();
        s = status(sl);
        allocator.free(sl);
        if (s == .Safe) {
            return s;
        }
    }
    return .Unsafe;
}

const Status = enum { Safe, Unsafe };

test "day2" {
    const alloc = std.testing.allocator;
    const TestData = struct {
        line: []const u8,
        status: Status,
    };
    const data: [6]TestData = .{
        TestData{ .line = "7 6 4 2 1", .status = .Safe },
        TestData{ .line = "1 2 7 8 9", .status = .Unsafe },
        TestData{ .line = "9 7 6 2 1", .status = .Unsafe },
        TestData{ .line = "1 3 2 4 5", .status = .Unsafe },
        TestData{ .line = "8 6 4 4 1", .status = .Unsafe },
        TestData{ .line = "1 3 6 7 9", .status = .Safe },
    };
    for (data) |td| {
        const parsed_line = try parse_line(alloc, td.line);
        const status_res = status(parsed_line);
        std.debug.print("{} : {any} : {}\n", .{ td, parsed_line, status_res });
        alloc.free(parsed_line);
        try std.testing.expectEqual(td.status, status_res);
    }
}

test "day2part2" {
    const alloc = std.testing.allocator;
    const TestData = struct {
        line: []const u8,
        status: Status,
    };
    const data: [6]TestData = .{
        TestData{ .line = "7 6 4 2 1", .status = .Safe },
        TestData{ .line = "1 2 7 8 9", .status = .Unsafe },
        TestData{ .line = "9 7 6 2 1", .status = .Unsafe },
        TestData{ .line = "1 3 2 4 5", .status = .Safe },
        TestData{ .line = "8 6 4 4 1", .status = .Safe },
        TestData{ .line = "1 3 6 7 9", .status = .Safe },
    };
    for (data) |td| {
        const parsed_line = try parse_line(alloc, td.line);
        const status_res = status_dampen(alloc, parsed_line);
        std.debug.print("{} : {any} : {any}\n", .{ td, parsed_line, status_res });
        alloc.free(parsed_line);
        try std.testing.expectEqual(td.status, status_res);
    }
}
