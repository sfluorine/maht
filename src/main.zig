const std = @import("std");
const AutoHashMap = std.AutoHashMap;
const ast = @import("./ast.zig");
const Lexer = @import("./lexer.zig");
const Parser = @import("./parser.zig");

fn evaluate_ast(node: ast.ExpressionNode) i64 {
    switch (node) {
        .LiteralExpr => return node.LiteralExpr.IntLiteral,
        .BinaryExpr => {
            const lhs = evaluate_ast(node.BinaryExpr.lhs);
            const rhs = evaluate_ast(node.BinaryExpr.rhs);

            switch (node.BinaryExpr.binop) {
                .Add => return lhs + rhs,
                .Sub => return lhs - rhs,
                .Mul => return lhs * rhs,
                .Div => return @divExact(lhs, rhs),
                .Mod => return @mod(lhs, rhs),
            }
        },
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var precedences = AutoHashMap(Lexer.TokenKind, u8).init(allocator);
    defer precedences.deinit();

    try precedences.put(Lexer.TokenKind.IntLiteral, 0);
    try precedences.put(Lexer.TokenKind.SymPlus, 1);
    try precedences.put(Lexer.TokenKind.SymMinus, 1);
    try precedences.put(Lexer.TokenKind.SymStar, 2);
    try precedences.put(Lexer.TokenKind.SymSlash, 2);
    try precedences.put(Lexer.TokenKind.SymPercent, 2);

    const stdin = std.io.getStdIn().reader();
    var input_buffer: [256]u8 = undefined;

    while (true) {
        if (try stdin.readUntilDelimiterOrEof(input_buffer[0..], '\n')) |user_input| {
            var lexer = Lexer.init(user_input, allocator);
            var tokens = lexer.scan() catch |err| {
                std.log.err("{}", .{err});
                continue;
            };

            defer tokens.deinit();

            const slice_tokens = tokens.items;
            var parser = Parser.init(slice_tokens, precedences, allocator);

            var binary_ast = parser.parse_expression(0) catch |err| {
                std.log.err("{}", .{err});
                continue;
            };

            defer binary_ast.deinit(allocator);
            std.debug.print("result: {d}\n", .{evaluate_ast(binary_ast)});
        }
    }
}
