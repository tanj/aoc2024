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

    const input: std.fs.File = try std.fs.cwd().openFile("src/input1.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var list_left = std.ArrayList(i64).init(arena.allocator());
    var list_right = std.ArrayList(i64).init(arena.allocator());
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            var it_tok = std.mem.tokenizeScalar(u8, line, ' ');
            var val = try parseInt(i64, it_tok.next().?, 10);
            try list_left.append(val);
            val = try parseInt(i64, it_tok.next().?, 10);
            try list_right.append(val);
            std.debug.assert(it_tok.next() == null);
        }
    }
    const left = try list_left.toOwnedSlice();
    const right = try list_right.toOwnedSlice();
    const distance = find_distance(left, right);
    const sim = find_sim(left, right);
    try stdout.print("Distance: {d}\n", .{distance});
    try stdout.print("Similarity: {d}\n", .{sim});
    try bw.flush();
}

fn find_distance(left: []i64, right: []i64) i64 {
    std.mem.sort(i64, left, void{}, std.sort.asc(i64));
    std.mem.sort(i64, right, void{}, std.sort.asc(i64));

    var sum: i64 = 0;
    for (left, right) |l, r| {
        sum += @intCast(@abs(l - r));
    }
    return sum;
}

fn find_sim(left: []i64, right: []i64) i64 {
    var sim: i64 = 0;
    for (left) |l| {
        const needle: []const i64 = &.{l};
        const c: i64 = @intCast(std.mem.count(i64, right, needle));
        sim += l * c;
    }
    return sim;
}

test "distance" {
    var left = [_]i64{ 3, 4, 2, 1, 3, 3 };
    var right = [_]i64{ 4, 3, 5, 3, 9, 3 };
    var start: usize = 0;
    _ = &start;
    try std.testing.expectEqual(11, find_distance(left[start..], right[start..]));
    try std.testing.expectEqual(31, find_sim(left[0..], right[0..]));
}
