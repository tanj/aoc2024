const std = @import("std");
const parseInt = std.fmt.parseInt;

const Grid = struct {
    x: i32,
    y: i32,
};

fn find_harmonic_antinodes(allocator: std.mem.Allocator, input: []const u8) !usize {
    var it_line = std.mem.splitScalar(u8, input, '\n');
    var antennas = std.AutoHashMap(u8, std.ArrayList(Grid)).init(allocator);
    defer antennas.deinit();
    var il: i32 = 0;
    var max_grid: Grid = .{ .x = 0, .y = 0 };
    while (it_line.next()) |line| : (il += 1) {
        if (line.len == 0) {
            break;
        }
        for (line, 0..) |value, ic| {
            max_grid.x = @intCast(ic);
            if (value != '.') {
                if (antennas.getKey(value)) |k| {
                    // if (antennas.get(k)) |*v| {
                    //     try v.append(.{ .x = max_grid.x, .y = il });
                    // }
                    var v = antennas.getPtr(k);
                    if (v) |*ant| {
                        try ant.*.append(.{ .x = max_grid.x, .y = il });
                    }
                } else {
                    var ant = std.ArrayList(Grid).init(allocator);
                    try ant.append(.{ .x = max_grid.x, .y = il });
                    try antennas.put(value, ant);
                }
            }
        }
        max_grid.y = il;
    }
    std.debug.print("max_grid: {any}\n", .{max_grid});
    var antinode = std.AutoHashMap(Grid, u8).init(allocator);
    defer antinode.deinit();
    var it_val = antennas.valueIterator();
    while (it_val.next()) |ant| {
        // std.debug.print("\nitems: {any}\n", .{ant.items});
        for (ant.items) |a| {
            for (ant.items) |b| {
                if (!std.meta.eql(a, b)) {
                    const distance = Grid{
                        .x = a.x - b.x,
                        .y = a.y - b.y,
                    };
                    var harm: i32 = 1;
                    var anti1_off_grid: bool = false;
                    var anti2_off_grid: bool = false;
                    while (!(anti1_off_grid and anti2_off_grid)) : (harm += 1) {
                        const anti1 = Grid{
                            .x = a.x - (distance.x * harm),
                            .y = a.y - (distance.y * harm),
                        };
                        if (anti1.x >= 0 and anti1.x <= max_grid.x and anti1.y >= 0 and anti1.y <= max_grid.y) {
                            var count = antinode.get(anti1);
                            if (count) |*v| {
                                v.* += 1;
                            } else {
                                try antinode.put(anti1, 1);
                            }
                        } else if (!std.meta.eql(anti1, b)) {
                            anti1_off_grid = true;
                        }
                        const anti2 = Grid{
                            .x = b.x - (distance.x * harm),
                            .y = b.y - (distance.y * harm),
                        };
                        if (anti2.x >= 0 and anti2.x <= max_grid.x and anti2.y >= 0 and anti2.y <= max_grid.y) {
                            var count = antinode.get(anti2);
                            if (count) |*v| {
                                v.* += 1;
                            } else {
                                try antinode.put(anti2, 1);
                            }
                        } else if (!std.meta.eql(anti2, a)) {
                            anti2_off_grid = true;
                        }
                    }
                }
            }
        }
        ant.deinit();
    }
    // var plot = [12][12]u8{
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    // };
    // var it_an = antinode.keyIterator();
    // while (it_an.next()) |k| {
    //     // std.debug.print("{any}\n", .{k});
    //     plot[@intCast(k.y)][@intCast(k.x)] = '#';
    // }
    // for (plot) |row| {
    //     std.debug.print("{s}\n", .{row});
    // }
    return antinode.count();
}

test "day 8 part 2" {
    const input: []const u8 =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;
    // std.debug.print("{s}\n", .{input});
    try std.testing.expectEqual(34, try find_harmonic_antinodes(std.testing.allocator, input));
}

fn find_antinodes(allocator: std.mem.Allocator, input: []const u8) !usize {
    var it_line = std.mem.splitScalar(u8, input, '\n');
    var antennas = std.AutoHashMap(u8, std.ArrayList(Grid)).init(allocator);
    defer antennas.deinit();
    var il: i32 = 0;
    var max_grid: Grid = .{ .x = 0, .y = 0 };
    while (it_line.next()) |line| : (il += 1) {
        if (line.len == 0) {
            break;
        }
        for (line, 0..) |value, ic| {
            max_grid.x = @intCast(ic);
            if (value != '.') {
                if (antennas.getKey(value)) |k| {
                    // if (antennas.get(k)) |*v| {
                    //     try v.append(.{ .x = max_grid.x, .y = il });
                    // }
                    var v = antennas.getPtr(k);
                    if (v) |*ant| {
                        try ant.*.append(.{ .x = max_grid.x, .y = il });
                    }
                } else {
                    var ant = std.ArrayList(Grid).init(allocator);
                    try ant.append(.{ .x = max_grid.x, .y = il });
                    try antennas.put(value, ant);
                }
            }
        }
        max_grid.y = il;
    }
    std.debug.print("max_grid: {any}\n", .{max_grid});
    var antinode = std.AutoHashMap(Grid, u8).init(allocator);
    defer antinode.deinit();
    var it_val = antennas.valueIterator();
    while (it_val.next()) |ant| {
        // std.debug.print("\nitems: {any}\n", .{ant.items});
        for (ant.items) |a| {
            for (ant.items) |b| {
                if (!std.meta.eql(a, b)) {
                    const distance = Grid{
                        .x = a.x - b.x,
                        .y = a.y - b.y,
                    };
                    const anti1 = Grid{
                        .x = a.x - distance.x,
                        .y = a.y - distance.y,
                    };
                    if (anti1.x >= 0 and anti1.x <= max_grid.x and anti1.y >= 0 and anti1.y <= max_grid.y and !std.meta.eql(anti1, b)) {
                        var count = antinode.get(anti1);
                        if (count) |*v| {
                            v.* += 1;
                        } else {
                            try antinode.put(anti1, 1);
                        }
                    }
                    const anti2 = Grid{
                        .x = b.x - distance.x,
                        .y = b.y - distance.y,
                    };
                    if (anti2.x >= 0 and anti2.x <= max_grid.x and anti2.y >= 0 and anti2.y <= max_grid.y and !std.meta.eql(anti2, a)) {
                        var count = antinode.get(anti2);
                        if (count) |*v| {
                            v.* += 1;
                        } else {
                            try antinode.put(anti2, 1);
                        }
                    }
                }
            }
        }
        ant.deinit();
    }
    // var plot = [12][12]u8{
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    //     [_]u8{'.'} ** 12,
    // };
    // var it_an = antinode.keyIterator();
    // while (it_an.next()) |k| {
    //     // std.debug.print("{any}\n", .{k});
    //     plot[@intCast(k.y)][@intCast(k.x)] = '#';
    // }
    // for (plot) |row| {
    //     std.debug.print("{s}\n", .{row});
    // }
    return antinode.count();
}

test "day 7 part 1" {
    const input: []const u8 =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;
    // std.debug.print("{s}\n", .{input});
    try std.testing.expectEqual(14, try find_antinodes(std.testing.allocator, input));
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

    const input: std.fs.File = try std.fs.cwd().openFile("src/input8.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [30000]u8 = undefined;
    const read = try in_stream.readAll(&buf);
    std.debug.print("read {d}\n", .{read});

    const result = try find_antinodes(arena.allocator(), buf[0..read]);
    try stdout.print("Result: {d}\n", .{result});
    const result2 = try find_harmonic_antinodes(arena.allocator(), buf[0..read]);
    try stdout.print("Result 2: {d}\n", .{result2});
    try bw.flush();
}
