const std = @import("std");
const navigation = @import("navigation.zig");
const handleCommand = @import("handleCommand.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;
    var cwdBuffer: [std.fs.max_path_bytes]u8 = undefined;
    _ = try std.fs.cwd().realpath(".", &cwdBuffer);
    navigation.cwd.setCwd(&cwdBuffer);

    while (true) {
        try stdout.print("$ ", .{});
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        try handleCommand.handler(user_input);
    }
}
