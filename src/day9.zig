const std = @import("std");
const parseInt = std.fmt.parseInt;

const max_usize = std.math.maxInt(usize);

fn defrag(allocator: std.mem.Allocator, input: []const u8) !usize {
    var fs = std.ArrayList(usize).init(allocator);
    defer fs.deinit();
    var ix_f: usize = 0;
    var ix_e: usize = 1;
    var fh: usize = 0;
    // generate disk map
    while (ix_f < input.len) : ({
        ix_f += 2;
        ix_e += 2;
        fh += 1;
    }) {
        if (input[ix_f] >= '0' and input[ix_f] <= '9') {
            const fb: u8 = input[ix_f] - '0';
            try fs.appendNTimes(fh, fb);
        }
        if (ix_e < input.len) {
            if (input[ix_e] >= '0' and input[ix_e] <= '9') {
                const eb: u8 = input[ix_e] - '0';
                try fs.appendNTimes(max_usize, eb);
            }
        }
    }
    // defrag map
    var head: usize = 0;
    var tail: usize = fs.items.len - 1;
    while (head < tail) : (head += 1) {
        if (fs.items[head] != max_usize) {
            continue;
        }
        while (tail > head and fs.items[tail] == max_usize) : (tail -= 1) {}
        fs.items[head] = fs.items[tail];
        fs.items[tail] = max_usize;
    }
    // crc map
    var checksum: usize = 0;
    var pos: usize = 0;
    while (pos < fs.items.len and fs.items[pos] != max_usize) : (pos += 1) {
        checksum += pos * fs.items[pos];
    }
    return checksum;
}

test "day 9 part 1" {
    //
    const input: []const u8 = "2333133121414131402";
    const result = try defrag(std.testing.allocator, input);
    try std.testing.expectEqual(1928, result);
}

fn defrag2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var fs = std.ArrayList(usize).init(allocator);
    defer fs.deinit();
    var ix_f: usize = 0;
    var ix_e: usize = 1;
    var fh: usize = 0;
    // generate disk map
    while (ix_f < input.len) : ({
        ix_f += 2;
        ix_e += 2;
        fh += 1;
    }) {
        if (input[ix_f] >= '0' and input[ix_f] <= '9') {
            const fb: u8 = input[ix_f] - '0';
            try fs.appendNTimes(fh, fb);
        }
        if (ix_e < input.len) {
            if (input[ix_e] >= '0' and input[ix_e] <= '9') {
                const eb: u8 = input[ix_e] - '0';
                try fs.appendNTimes(max_usize, eb);
            }
        }
    }
    // defrag map
    var tail: usize = fs.items.len - 1;
    // fh is currently the next fh so lets make it the current
    fh -= 1;
    while (fh > 0) : ({
        fh -= 1;
    }) {
        // find next fh and it's length
        var len: usize = 0;
        var fh_start: usize = 0;
        while (tail > 0 and (fs.items[tail] == max_usize or fs.items[tail] >= fh)) : (tail -= 1) {
            if (fs.items[tail] == fh) {
                len += 1;
                fh_start = tail;
            }
        }
        tail = fh_start;
        // look for free space
        var head: usize = 0;
        var free_start: usize = max_usize;
        move_file: while (head < fh_start) : (head += 1) {
            if (fs.items[head] == max_usize) {
                if (free_start == max_usize) {
                    free_start = head;
                }
                if (head - free_start + 1 == len) {
                    var ix: usize = 0;
                    while (ix < len) : (ix += 1) {
                        fs.items[fh_start + ix] = max_usize;
                        fs.items[free_start + ix] = fh;
                    }
                    break :move_file;
                }
            } else {
                free_start = max_usize;
            }
        }
    }
    // crc map
    var checksum: usize = 0;
    var pos: usize = 0;
    while (pos < fs.items.len) : (pos += 1) {
        if (fs.items[pos] != max_usize) {
            checksum += pos * fs.items[pos];
        }
    }
    return checksum;
}
test "day 9 part 2" {
    //
    const input: []const u8 = "2333133121414131402";
    const result = try defrag2(std.testing.allocator, input);
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

    const input: std.fs.File = try std.fs.cwd().openFile("src/input9.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [30000]u8 = undefined;
    const read = try in_stream.readAll(&buf);
    std.debug.print("read {d}\n", .{read});

    const result = try defrag(arena.allocator(), buf[0..read]);
    try stdout.print("Result: {d}\n", .{result});
    const result2 = try defrag2(arena.allocator(), buf[0..read]);
    try stdout.print("Result 2: {d}\n", .{result2});
    try bw.flush();
}
