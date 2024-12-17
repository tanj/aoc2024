const std = @import("std");
const mecha = @import("mecha");

const parseInt = std.fmt.parseInt;

const Operation = enum { mul };
const MullOp = struct {
    op: Operation,
    lhs: i64,
    rhs: i64,
};

const num = mecha.int(i16, .{
    .parse_sign = false,
    .base = 10,
    .max_digits = 3,
});
const op = mecha.enumeration(Operation);
const lparen = mecha.utf8.char('(');
const rparen = mecha.utf8.char(')');
const comma = mecha.utf8.char(',');
const mullop = mecha.combine(.{
    op,
    lparen.discard(),
    num,
    comma.discard(),
    num,
    rparen.discard(),
});
const make_mullop = mullop.map(mecha.toStruct(MullOp));
const find_mull = mecha.combine(.{
    mecha.many(mecha.utf8.not(mullop), .{}).discard(),
    make_mullop,
    // mecha.many(mecha.utf8.not(mullop), .{ .max = 5 }).discard(),
    // mecha.opt(mecha.utf8.not(mullop)).discard(),
});
const sep = mecha.opt(mecha.many(mecha.utf8.not(mullop), .{})).discard();
const parse_line = mecha.many(find_mull, .{ .separator = sep });

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const input: std.fs.File = try std.fs.cwd().openFile("src/input3.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [4096]u8 = undefined;
    var result: i128 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            const res = try parse_line.parse(arena.allocator(), line);
            for (res.value) |mull| {
                result += mull.lhs * mull.rhs;
            }
            std.debug.print("{}\n", .{res});
        }
    }
    try stdout.print("Result: {d}\n", .{result});
    try bw.flush();
}

test "parser" {
    const alloc = std.testing.allocator;
    const a = (try make_mullop.parse(alloc, "mul(1,2)")).value;
    try std.testing.expectEqual(Operation.mul, a.op);
    try std.testing.expectEqual(1, a.lhs);
    try std.testing.expectEqual(2, a.rhs);
}
test "parser fail" {
    const alloc = std.testing.allocator;
    try mecha.expectResult(MullOp, mecha.Error.ParserFailed, make_mullop.parse(alloc, "amul(1,2)"));
}
// test "parser find" {
//     const alloc = std.testing.allocator;
//     const a = (try find_mull.parse(alloc, "amul(1,2)")).value;
//     std.debug.print("{any}\n", .{a});
//     alloc.free(a);
// }
test "parser find all" {
    const alloc = std.testing.allocator;
    const a = try parse_line.parse(alloc, "amul(1,2)#$&mul()mul(3,4)mul(123,456]mul(567,890)");
    // try std.testing.expect(a.value.len > 0);
    std.debug.print("{any}\n", .{a});
}
