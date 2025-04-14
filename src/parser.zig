const std = @import("std");
const lexer = @import("lexer.zig");

pub const AstNodeType = enum {
    FunctionDecl,
    PrintStmt,
};

pub const AstNode = union(AstNodeType) {
    FunctionDecl: struct {
        name: []const u8,
        body: []AstNode,
    },
    PrintStmt: struct {
        message: []const u8,
    },
};

const Current = struct {
    tokens: []lexer.Token,
    i: *usize,

    pub fn token(self: *Current) lexer.Token {
        return self.tokens[self.i.*];
    }

    pub fn advance(self: *Current) void {
        self.i.* += 1;
    }
};

pub fn parse(allocator: std.mem.Allocator, tokens: []lexer.Token) !AstNode {
    var i: usize = 0;

    var current = Current{
        .tokens = tokens,
        .i = &i,
    };

    // Expect: def <name> () -> void:
    if (current.token().typ != lexer.TokenType.KeywordDef) {
        return error.ExpectedDef;
    }
    current.advance();

    if (current.token().typ != lexer.TokenType.Identifier) {
        return error.ExpectedFunctionName;
    }
    const func_name = current.token().value;
    current.advance();

    if (current.token().typ != lexer.TokenType.LParen) {
        return error.ExpectedLParen;
    }
    current.advance();

    if (current.token().typ != lexer.TokenType.RParen) {
        return error.ExpectedRParen;
    }
    current.advance();

    if (current.token().typ != lexer.TokenType.Arrow) {
        return error.ExpectedArrow;
    }
    current.advance();

    if (current.token().typ != lexer.TokenType.Identifier) {
        return error.ExpectedReturnType;
    }
    if (!std.mem.eql(u8, current.token().value, "void")) {
        return error.ExpectedVoidReturn;
    }
    current.advance();

    if (current.token().typ != lexer.TokenType.Colon) {
        return error.ExpectedColon;
    }
    current.advance();

    // Expect a Newline (start of function body)
    if (current.token().typ != lexer.TokenType.Newline) {
        return error.ExpectedNewline;
    }
    current.advance();

    // Now inside the function body: expect a print statement
    if (current.token().typ != lexer.TokenType.KeywordPrint) {
        return error.ExpectedPrint;
    }
    current.advance();

    if (current.token().typ != lexer.TokenType.LParen) {
        return error.ExpectedLParenPrint;
    }
    current.advance();

    if (current.token().typ != lexer.TokenType.StringLiteral) {
        return error.ExpectedStringLiteral;
    }
    const message = current.token().value;
    current.advance();

    if (current.token().typ != lexer.TokenType.RParen) {
        return error.ExpectedRParenPrint;
    }
    current.advance();

    const print_stmt = AstNode{ .PrintStmt = .{ .message = message } };

    var body = std.ArrayList(AstNode).init(allocator);
    try body.append(print_stmt);

    return AstNode{
        .FunctionDecl = .{
            .name = func_name,
            .body = try body.toOwnedSlice(),
        },
    };
}
