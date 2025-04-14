const std = @import("std");
const parser = @import("parser.zig");

pub fn generate(allocator: std.mem.Allocator, tree: parser.AstNode, filename: []const u8) !void {
    // Create output directory if needed
    try std.fs.cwd().makePath("out");

    // Extract a base name like "hello" from "examples/hello.vy"
    const slash_pos = std.mem.lastIndexOfScalar(u8, filename, '/') orelse 0;
    const dot_pos = std.mem.lastIndexOfScalar(u8, filename, '.') orelse filename.len;
    const basename = filename[slash_pos..dot_pos];

    // Full output C file path
    const full_path_buf = try std.mem.concat(allocator, u8, &[_][]const u8{
        "out", basename, ".c",
    });
    defer allocator.free(full_path_buf);

    var file = try std.fs.cwd().createFile(full_path_buf, .{ .truncate = true });
    defer file.close();

    var writer = file.writer();

    try writer.print("#include <stdio.h>\n\n", .{});

    // Start main function
    try writer.print("int main() {{\n", .{});

    // Now emit the body
    switch (tree) {
        .FunctionDecl => |func| {
            for (func.body) |stmt| {
                switch (stmt) {
                    .PrintStmt => |p| {
                        try writer.print("    printf(\"{s}\\n\");\n", .{p.message});
                    },
                    else => return error.UnsupportedStatement,
                }
            }
        },
        else => return error.UnsupportedTopLevelNode,
    }

    try writer.print("    return 0;\n", .{});
    try writer.print("}}\n", .{});

    // Now compile the C file into an executable
    // Target binary name
    const output_bin = try std.mem.concat(allocator, u8, &[_][]const u8{
        "out", basename,
    });
    defer allocator.free(output_bin);

    var child = std.process.Child.init(
        &[_][]const u8{
            "zig", "cc", "-o", output_bin, full_path_buf,
        },
        allocator,
    );

    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    try child.spawn();
    const term = try child.wait();

    if (term != .Exited or term.Exited != 0) {
        return error.CCompilationFailed;
    }
}
