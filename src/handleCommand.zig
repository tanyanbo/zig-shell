const std = @import("std");

pub fn handler(input: []u8) !void {
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
        try handleEcho(input);
    } else if (std.mem.eql(u8, command.?, "type")) {
        try handleType(input);
    } else {
        try handleUnknownCommands(input);
    }
}

fn handleType(input: []u8) !void {
    const stdout = std.io.getStdOut().writer();
    const builtins = [_][]const u8{ "echo", "type", "exit" };
    var argsIter = std.mem.splitSequence(u8, input[5..], " ");

    while (argsIter.next()) |arg| {
        const res = for (builtins) |builtin| {
            if (std.mem.eql(u8, builtin, arg)) {
                break true;
            }
        } else false;
        if (res) {
            try stdout.print("{s} is a shell builtin\n", .{arg});
        } else {
            try stdout.print("{s}: not found\n", .{arg});
        }
    }
}

fn handleEcho(input: []u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{input[5..]});
}

fn handleUnknownCommands(input: []u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}: command not found\n", .{input});
}
