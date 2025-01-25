const std = @import("std");

pub fn handler(input: []u8) !void {
    const stdout = std.io.getStdOut().writer();

    if (std.mem.eql(u8, input, "exit 0")) {
        std.process.exit(0);
        return;
    }

    try stdout.print("{s}: command not found\n", .{input});
}
