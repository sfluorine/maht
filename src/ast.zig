const std = @import("std");
const Allocator = std.mem.Allocator;

pub const ExpressionNode = union(enum) {
    const Self = @This();

    LiteralExpr: ParsedLiteralExpression,
    BinaryExpr: *ParsedBinaryExpression,

    pub fn deinit(self: *Self, allocator: Allocator) void {
        switch (self.*) {
            .LiteralExpr => {},
            .BinaryExpr => self.BinaryExpr.deinit(allocator),
        }
    }
};

pub const ParsedLiteralExpression = union(enum) {
    IntLiteral: i64,
};

pub const BinaryOperator = enum {
    Add,
    Sub,
    Mul,
    Div,
    Mod,
};

pub const ParsedBinaryExpression = struct {
    const Self = @This();

    binop: BinaryOperator,
    lhs: ExpressionNode,
    rhs: ExpressionNode,

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.lhs.deinit(allocator);
        self.rhs.deinit(allocator);
        allocator.destroy(self);
    }
};
