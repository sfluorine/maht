const std = @import("std");
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;

const ast = @import("./ast.zig");
const Lexer = @import("./lexer.zig");

const Self = @This();

tokens: []const Lexer.Token,
precedences: AutoHashMap(Lexer.TokenKind, u8),
allocator: Allocator,

fn is_eof(self: *const Self) bool {
    return self.tokens[0].kind == Lexer.TokenKind.EndOfFile;
}

fn advance(self: *Self) void {
    if (self.is_eof())
        return;

    self.tokens = self.tokens[1..];
}

fn match_token(self: *Self, kind: Lexer.TokenKind) error{SyntaxError}!void {
    if (self.tokens[0].kind != kind)
        return error.SyntaxError;

    self.advance();
}

fn get_op_precedence(self: *const Self) error{InvalidPrecedenceToken}!u8 {
    const val = self.precedences.get(self.tokens[0].kind);

    if (val == null)
        return error.InvalidPrecedenceToken;

    if (val.? == 0)
        return error.InvalidPrecedenceToken;

    return val.?;
}

fn parse_primary(self: *Self) !ast.ExpressionNode {
    const current = self.tokens[0];
    try self.match_token(Lexer.TokenKind.IntLiteral);

    const value = try std.fmt.parseInt(i64, current.view, 10);
    return ast.ExpressionNode{ .LiteralExpr = ast.ParsedLiteralExpression{ .IntLiteral = value } };
}

pub fn parse_expression(self: *Self, prec: u8) !ast.ExpressionNode {
    var left = try self.parse_primary();

    if (self.is_eof())
        return left;

    const new_prec = try self.get_op_precedence();
    while (prec < new_prec) {
        const binop = switch (self.tokens[0].kind) {
            Lexer.TokenKind.SymPlus => ast.BinaryOperator.Add,
            Lexer.TokenKind.SymMinus => ast.BinaryOperator.Sub,
            Lexer.TokenKind.SymStar => ast.BinaryOperator.Mul,
            Lexer.TokenKind.SymSlash => ast.BinaryOperator.Div,
            Lexer.TokenKind.SymPercent => ast.BinaryOperator.Mod,
            else => unreachable,
        };

        self.advance();

        var right = try self.parse_expression(new_prec);

        var parsed_binary_expr = try self.allocator.create(ast.ParsedBinaryExpression);
        parsed_binary_expr.binop = binop;
        parsed_binary_expr.lhs = left;
        parsed_binary_expr.rhs = right;

        const binary_expr = ast.ExpressionNode{ .BinaryExpr = parsed_binary_expr };
        left = binary_expr;

        if (self.is_eof())
            return left;
    }

    return left;
}

pub fn init(tokens: []const Lexer.Token, precedences: AutoHashMap(Lexer.TokenKind, u8), allocator: Allocator) Self {
    return Self{
        .tokens = tokens,
        .precedences = precedences,
        .allocator = allocator,
    };
}
