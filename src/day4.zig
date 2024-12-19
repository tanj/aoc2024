const std = @import("std");

const parseInt = std.fmt.parseInt;
const max_grid = 141;

const SearchResult = struct {
    std: u64,
    x: u64,
};

fn word_search(haystack: []const u8) SearchResult {
    var grid: [max_grid][max_grid]u8 = undefined;
    var h: u8 = 0;
    var v: u8 = 0;
    var act_grid: u8 = 0;
    for (haystack) |c| {
        if (c != '\n' and h < max_grid) {
            grid[v][h] = c;
            h += 1;
        } else {
            grid[v][h] = 0;
            if (act_grid == 0) {
                act_grid = h;
            }
            h = 0;
            v += 1;
        }
    }
    const fwd = [_]u8{ 'X', 'M', 'A', 'S' };
    const rev = [_]u8{ 'S', 'A', 'M', 'X' };
    h = 0;
    v = 0;
    var result = SearchResult{ .std = 0, .x = 0 };
    while (v < act_grid) : (v += 1) {
        h = 0;
        while (h < act_grid) : (h += 1) {
            std.debug.print("v: {d} h:{d}\n", .{ v, h });
            if (h < act_grid - 3) {
                result.std += check_horz(&grid, fwd, h, v);
                result.std += check_horz(&grid, rev, h, v);
                if (v < act_grid - 3) {
                    result.std += check_diag_lr(&grid, fwd, h, v);
                    result.std += check_diag_lr(&grid, rev, h, v);
                }
            }
            if (h > 2) {
                if (v < act_grid - 3) {
                    result.std += check_diag_rl(&grid, fwd, h, v);
                    result.std += check_diag_rl(&grid, rev, h, v);
                }
            }
            if (v < act_grid - 3) {
                result.std += check_vert(&grid, fwd, h, v);
                result.std += check_vert(&grid, rev, h, v);
            }
            if ((h < act_grid - 1 and h > 0) and (v > 0 and v < act_grid - 1)) {
                result.x += check_cross(&grid, h, v);
            }
        }
    }

    return result;
}
fn check_horz(grid: *[max_grid][max_grid]u8, word: [4]u8, h: u8, v: u8) u8 {
    var i: u8 = 0;
    std.debug.print("{s} looking at horz: {s}: ", .{ word, grid[v][h .. h + 4] });
    while (i < 4 and grid[v][h + i] == word[i]) : (i += 1) {}
    if (i == 4) {
        std.debug.print("found\n", .{});
        return 1;
    }
    std.debug.print("not found\n", .{});
    return 0;
}
fn check_vert(grid: *[max_grid][max_grid]u8, word: [4]u8, h: u8, v: u8) u8 {
    var i: u8 = 0;
    const look = [_]u8{ grid[v][h], grid[v + 1][h], grid[v + 2][h], grid[v + 3][h] };
    std.debug.print("{s} looking at vert: {s}: ", .{ word, look });
    while (i < 4 and grid[v + i][h] == word[i]) : (i += 1) {}
    if (i == 4) {
        std.debug.print("found\n", .{});
        return 1;
    }
    std.debug.print("not found\n", .{});
    return 0;
}
fn check_diag_lr(grid: *[max_grid][max_grid]u8, word: [4]u8, h: u8, v: u8) u8 {
    var i: u8 = 0;
    const look = [_]u8{ grid[v][h], grid[v + 1][h + 1], grid[v + 2][h + 2], grid[v + 3][h + 3] };
    std.debug.print("{s} looking at diag lr: {s}: ", .{ word, look });
    while (i < 4 and grid[v + i][h + i] == word[i]) : (i += 1) {}
    if (i == 4) {
        std.debug.print("found\n", .{});
        return 1;
    }
    std.debug.print("not found\n", .{});
    return 0;
}
fn check_diag_rl(grid: *[max_grid][max_grid]u8, word: [4]u8, h: u8, v: u8) u8 {
    var i: u8 = 0;
    const look = [_]u8{ grid[v][h], grid[v + 1][h - 1], grid[v + 2][h - 2], grid[v + 3][h - 3] };
    std.debug.print("{s} looking at diag rl: {s}: ", .{ word, look });
    while (i < 4 and grid[v + i][h - i] == word[i]) : (i += 1) {}
    if (i == 4) {
        std.debug.print("found\n", .{});
        return 1;
    }
    std.debug.print("not found\n", .{});
    return 0;
}
fn check_cross(grid: *[max_grid][max_grid]u8, h: u8, v: u8) u8 {
    if ((grid[v][h] == 'A') and
        (((grid[v - 1][h - 1] == 'M' and grid[v + 1][h + 1] == 'S') or
        (grid[v - 1][h - 1] == 'S' and grid[v + 1][h + 1] == 'M')) and
        ((grid[v + 1][h - 1] == 'M' and grid[v - 1][h + 1] == 'S') or
        (grid[v + 1][h - 1] == 'S' and grid[v - 1][h + 1] == 'M'))))
    {
        std.debug.print("found\n", .{});
        return 1;
    }
    std.debug.print("not found\n", .{});
    return 0;
}
test "parse example" {
    const sample =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;
    const result = word_search(sample);
    try std.testing.expectEqual(18, result.std);
    try std.testing.expectEqual(9, result.x);
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

    const input: std.fs.File = try std.fs.cwd().openFile("src/input4.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [20000]u8 = undefined;
    const read = try in_stream.readAll(&buf);
    std.debug.print("read {d}\n", .{read});

    const result = word_search(buf[0..read]);
    try stdout.print("Result: {d}\n", .{result.std});
    try stdout.print("Result X-MAS: {d}\n", .{result.x});
    try bw.flush();
}
