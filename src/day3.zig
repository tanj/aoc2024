const std = @import("std");
const mecha = @import("mecha");

const parseInt = std.fmt.parseInt;

const Operation = enum { mul };
const MullOp = struct {
    op: Operation,
    lhs: i64,
    rhs: i64,
};
const Enable = enum { do, @"don't" };
const EnableOp = struct {
    op: Enable,
};
const OpTypeTag = enum { operation, enable };
const OpType = union(OpTypeTag) {
    operation: MullOp,
    enable: EnableOp,
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
const make_mullop: mecha.Parser(OpType) = mullop.map(mecha.toStruct(MullOp)).map(mecha.unionInit(
    OpType,
    OpTypeTag.operation,
));
const enable_operation = mecha.enumeration(Enable);
const enop = mecha.combine(.{
    enable_operation,
    lparen.discard(),
    rparen.discard(),
});
const make_enop: mecha.Parser(OpType) = enop.map(mecha.toStruct(EnableOp)).map(mecha.unionInit(
    OpType,
    OpTypeTag.enable,
));
const op_oneof = mecha.oneOf(.{
    enop.discard(),
    mullop.discard(),
});
const make_oponeof: mecha.Parser(OpType) = mecha.oneOf(.{
    make_enop,
    make_mullop,
});
const find_mull = mecha.combine(.{
    mecha.many(mecha.utf8.not(op_oneof), .{}).discard(),
    make_oponeof,
    // mecha.many(mecha.utf8.not(mullop), .{ .max = 5 }).discard(),
    // mecha.opt(mecha.utf8.not(mullop)).discard(),
});

const sep = mecha.opt(mecha.many(mecha.utf8.not(op_oneof), .{})).discard();
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
    var sup_result: i128 = 0;
    var apply = Enable.do;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            const res = try parse_line.parse(arena.allocator(), line);
            switch (res.value) {
                .ok => |val| {
                    for (val) |v| {
                        switch (v) {
                            .operation => |o| {
                                result += o.lhs * o.rhs;
                                if (apply == Enable.do) {
                                    sup_result += o.lhs * o.rhs;
                                }
                            },
                            .enable => |e| {
                                apply = e.op;
                            },
                        }
                    }
                },
                .err => |e| std.debug.print("parser error: {any}\n", .{e}),
            }
            // std.debug.print("{}\n", .{res});
        }
    }
    try stdout.print("Result: {d}\n", .{result});
    try stdout.print("Suppressed Result: {d}\n", .{sup_result});
    try bw.flush();
}

test "parser" {
    const alloc = std.testing.allocator;
    const a = (try make_mullop.parse(alloc, "mul(1,2)")).value.ok;
    try std.testing.expect(@as(OpTypeTag, a) == OpTypeTag.operation);
    switch (a) {
        OpTypeTag.operation => |v| {
            try std.testing.expectEqual(Operation.mul, v.op);
            try std.testing.expectEqual(1, v.lhs);
            try std.testing.expectEqual(2, v.rhs);
        },
        OpTypeTag.enable => unreachable,
    }
}
test "parser fail" {
    const alloc = std.testing.allocator;
    // try mecha.expectResult(MullOp, mecha.Error.ParserFailed, make_mullop.parse(alloc, "amul(1,2)"));
    try mecha.expectErr(OpType, 0, try make_mullop.parse(alloc, "amul(1,2)"));
}
// test "parser find" {
//     const alloc = std.testing.allocator;
//     const a = (try find_mull.parse(alloc, "amul(1,2)")).value;
//     std.debug.print("{any}\n", .{a});
//     alloc.free(a);
// }
test "parser find all" {
    const alloc = std.testing.allocator;
    const a = (try parse_line.parse(alloc, "amul(1,2)#do()$&mul()mul(3,4)don't()mul(123,456]do()mul(567,890)")).value.ok;
    try std.testing.expect(a.len > 0);
    std.debug.print("{any}\n", .{a});
    alloc.free(a);
}
