const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const codegen = @import("codegen.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: {s} build <file.vy>\n", .{args[0]});
        return error.InvalidArguments;
    }

    const command = args[1];
    if (!std.mem.eql(u8, command, "build")) {
        std.debug.print("Unknown command: {s}\n", .{command});
        return error.UnknownCommand;
    }

    const filename = args[2];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, 10 * 1024);
    defer allocator.free(source);

    const tokens = try lexer.tokenize(allocator, source);
    const tree = try parser.parse(allocator, tokens);
    try codegen.generate(allocator, tree, filename);
}
