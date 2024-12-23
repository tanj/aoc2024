const std = @import("std");

const max_grid: usize = 130;
const Position = struct {
    x: usize,
    y: usize,
};
const Dir = enum {
    up,
    down,
    left,
    right,
};

fn distinct_guard_positions(input: []const u8) usize {
    var grid: [max_grid][max_grid]u8 = undefined;
    for (&grid) |*g_inner| {
        for (g_inner) |*g| {
            g.* = 0;
        }
    }
    var it_line = std.mem.splitScalar(u8, input, '\n');
    var i: usize = 0;
    var g_pos = Position{ .x = 0, .y = 0 };
    while (it_line.next()) |line| : (i += 1) {
        if (line.len > 0) {
            std.mem.copyForwards(u8, &grid[i], line);
            const guard = std.mem.indexOfScalar(u8, line, '^');
            if (guard) |g| {
                g_pos.x = g;
                g_pos.y = i;
            }
        }
    }
    // follow guard path and mark it
    var dir = Dir.up;
    walk: while (true) {
        // mark our spot
        grid[g_pos.y][g_pos.x] = 'X';
        // walk
        switch (dir) {
            Dir.up => {
                if (g_pos.y > 0) {
                    if (grid[g_pos.y - 1][g_pos.x] != '#') {
                        g_pos.y -= 1;
                    } else {
                        dir = Dir.right;
                    }
                } else {
                    break :walk;
                }
            },
            Dir.right => {
                const look = grid[g_pos.y][g_pos.x + 1];
                if (g_pos.x < (max_grid - 1) and look != 0) {
                    if (look != '#') {
                        g_pos.x += 1;
                    } else {
                        dir = Dir.down;
                    }
                } else {
                    break :walk;
                }
            },
            Dir.down => {
                const look = grid[g_pos.y + 1][g_pos.x];
                if (g_pos.y < (max_grid - 1) and look != 0) {
                    if (look != '#') {
                        g_pos.y += 1;
                    } else {
                        dir = Dir.left;
                    }
                } else {
                    break :walk;
                }
            },
            Dir.left => {
                if (g_pos.x > 0) {
                    const look = grid[g_pos.y][g_pos.x - 1];
                    if (look != '#') {
                        g_pos.x -= 1;
                    } else {
                        dir = Dir.up;
                    }
                } else {
                    break :walk;
                }
            },
        }
    }
    // count distinct walked cells
    var count: usize = 0;
    for (grid) |line| {
        // std.debug.print("{s}\n", .{line});
        // count X cells
        for (line) |c| {
            if (c == 'X') {
                count += 1;
            }
        }
    }
    return count;
}

test "day 6 part 1" {
    const input: []const u8 =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    // std.debug.print("{s}\n", .{input});
    try std.testing.expectEqual(41, distinct_guard_positions(input));
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

    const input: std.fs.File = try std.fs.cwd().openFile("src/input6.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [20000]u8 = undefined;
    const read = try in_stream.readAll(&buf);
    std.debug.print("read {d}\n", .{read});

    const result = distinct_guard_positions(buf[0..read]);
    try stdout.print("Result: {d}\n", .{result});
    // try stdout.print("Result X-MAS: {d}\n", .{result.x});
    try bw.flush();
}
