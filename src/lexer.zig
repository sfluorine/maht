const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Self = @This();

input: []const u8,
line: u64,
cols: u64,
allocator: Allocator,

pub const TokenKind = enum {
    IntLiteral,
    SymPlus,
    SymMinus,
    SymStar,
    SymSlash,
    SymPercent,
    EndOfFile,
};

pub const Token = struct {
    kind: TokenKind,
    view: []const u8,
    line: u64,
    cols: u64,

    pub fn init(kind: TokenKind, view: []const u8, line: u64, cols: u64) Token {
        return Token{
            .kind = kind,
            .view = view,
            .line = line,
            .cols = cols,
        };
    }

    pub fn print(self: *const Token) void {
        std.debug.print("{d}:{d}: {s}\n", .{ self.line, self.cols, self.view });
    }
};

pub const LexerError = error{
    GarbageToken,
};

fn is_eof(self: *const Self) bool {
    return self.input.len == 0;
}

fn current_char(self: *const Self) u8 {
    if (self.is_eof())
        return 0;

    return self.input[0];
}

fn advance_char(self: *Self) void {
    if (self.is_eof())
        return;

    if (self.current_char() == '\n') {
        self.cols = 1;
        self.line += 1;
    } else {
        self.cols += 1;
    }

    self.input = self.input[1..];
}

pub fn scan(self: *Self) !ArrayList(Token) {
    var tokens = ArrayList(Token).init(self.allocator);

    if (self.is_eof()) {
        try tokens.append(Token.init(TokenKind.EndOfFile, self.input, self.line, self.cols));
        return tokens;
    }

    while (!self.is_eof()) {
        while (!self.is_eof() and std.ascii.isWhitespace(self.current_char()))
            self.advance_char();

        const start_view = self.input;
        const start_line = self.line;
        const start_cols = self.cols;

        switch (self.current_char()) {
            '+' => {
                self.advance_char();
                try tokens.append(Token.init(TokenKind.SymPlus, start_view[0..1], start_line, start_cols));
            },
            '-' => {
                self.advance_char();
                try tokens.append(Token.init(TokenKind.SymMinus, start_view[0..1], start_line, start_cols));
            },
            '*' => {
                self.advance_char();
                try tokens.append(Token.init(TokenKind.SymStar, start_view[0..1], start_line, start_cols));
            },
            '/' => {
                self.advance_char();
                try tokens.append(Token.init(TokenKind.SymSlash, start_view[0..1], start_line, start_cols));
            },
            '%' => {
                self.advance_char();
                try tokens.append(Token.init(TokenKind.SymPercent, start_view[0..1], start_line, start_cols));
            },
            '0'...'9' => {
                var length: u64 = 0;

                while (!self.is_eof() and std.ascii.isDigit(self.current_char())) {
                    length += 1;
                    self.advance_char();
                }

                try tokens.append(Token.init(TokenKind.IntLiteral, start_view[0..length], start_line, start_cols));
            },
            else => {
                tokens.deinit();
                return LexerError.GarbageToken;
            },
        }

        if (self.is_eof()) {
            try tokens.append(Token.init(TokenKind.EndOfFile, self.input, self.line, self.cols));
            return tokens;
        }
    }

    return tokens;
}

pub fn init(input: []const u8, allocator: Allocator) Self {
    return Self{
        .input = input,
        .line = 1,
        .cols = 1,
        .allocator = allocator,
    };
}
