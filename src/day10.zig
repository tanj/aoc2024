const std = @import("std");
const parseInt = std.fmt.parseInt;

fn score_trails(allocator: std.mem.Allocator, input: []const u8) !usize {
    //
}
test "day 10 part 1" {
    const input: []const u8 =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
        \\
    ;
    const result = try score_trails(std.testing.allocator, input);
    try std.testing.expectEqual(2858, result);
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

    const input: std.fs.File = try std.fs.cwd().openFile("src/input10.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [30000]u8 = undefined;
    const read = try in_stream.readAll(&buf);
    std.debug.print("read {d}\n", .{read});

    const result = try score_trails(arena.allocator(), buf[0..read]);
    try stdout.print("Result: {d}\n", .{result});
    // const result2 = try defrag2(arena.allocator(), buf[0..read]);
    // try stdout.print("Result 2: {d}\n", .{result2});
    try bw.flush();
}
