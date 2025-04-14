const std = @import("std");

pub const TokenType = enum {
    KeywordDef,
    KeywordPrint,
    Identifier,
    StringLiteral,
    LParen,
    RParen,
    Colon,
    Arrow,
    Newline,
    Eof,
};

pub const Token = struct {
    typ: TokenType,
    value: []const u8,
};

pub fn tokenize(allocator: std.mem.Allocator, source: []const u8) ![]Token {
    var tokens = std.ArrayList(Token).init(allocator);
    var i: usize = 0;

    while (i < source.len) {
        const c = source[i];

        // Only skip spaces and tabs but NOT newlines.
        if (c == ' ' or c == '\t') {
            i += 1;
            continue;
        }

        if (std.ascii.isAlphabetic(c)) {
            const start = i;
            while (i < source.len and (std.ascii.isAlphabetic(source[i]) or source[i] == '_')) {
                i += 1;
            }
            const ident = source[start..i];
            const typ = if (std.mem.eql(u8, ident, "def")) TokenType.KeywordDef else if (std.mem.eql(u8, ident, "print")) TokenType.KeywordPrint else TokenType.Identifier;
            try tokens.append(Token{ .typ = typ, .value = ident });
            continue;
        }

        switch (c) {
            '"' => {
                i += 1;
                const start = i;
                while (i < source.len and source[i] != '"') {
                    i += 1;
                }
                if (i >= source.len) {
                    return error.UnterminatedString;
                }
                const strval = source[start..i];
                i += 1; // Skip closing quote
                try tokens.append(Token{ .typ = TokenType.StringLiteral, .value = strval });
            },
            '(' => {
                try tokens.append(Token{ .typ = TokenType.LParen, .value = "(" });
                i += 1;
            },
            ')' => {
                try tokens.append(Token{ .typ = TokenType.RParen, .value = ")" });
                i += 1;
            },
            ':' => {
                try tokens.append(Token{ .typ = TokenType.Colon, .value = ":" });
                i += 1;
            },
            '-' => {
                if (i + 1 < source.len and source[i + 1] == '>') {
                    try tokens.append(Token{ .typ = TokenType.Arrow, .value = "->" });
                    i += 2;
                } else {
                    return error.UnknownCharacter;
                }
            },
            '\n' => {
                try tokens.append(Token{ .typ = TokenType.Newline, .value = "\n" });
                i += 1;
            },
            else => {
                return error.UnknownCharacter;
            },
        }
    }

    try tokens.append(Token{ .typ = TokenType.Eof, .value = "" });
    return tokens.toOwnedSlice();
}
