const std = @import("std");

pub fn handler(input: []u8) !void {
    const stdout = std.io.getStdOut().writer();
    var iter = std.mem.splitSequence(u8, input, " ");

    const command = iter.next();

    if (command == null) {
        std.process.exit(1);
        return;
    }

    if (std.mem.eql(u8, command.?, "exit")) {
        const exitCode = iter.next();
        if (exitCode == null) {
            std.process.exit(6);
        }
        const intExitCode = std.fmt.parseInt(u8, exitCode.?, 10) catch 5;
        std.process.exit(intExitCode);
    } else if (std.mem.eql(u8, command.?, "echo")) {
        try stdout.print("{s}\n", .{input[5..]});
    } else {
        try stdout.print("{s}: command not found\n", .{input});
    }
}
