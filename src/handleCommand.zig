const std = @import("std");

const stdout = std.io.getStdOut().writer();

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
            try findBinInPath(arg);
        }
    }
}

fn findBinInPath(arg: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const pathValue = try std.process.getEnvVarOwned(allocator, "PATH");
    defer {
        allocator.free(pathValue);
        _ = gpa.deinit();
    }

    var pathIter = std.mem.splitSequence(u8, pathValue, ":");
    while (pathIter.next()) |path| {
        var dir = std.fs.openDirAbsolute(path, .{ .iterate = true }) catch {
            continue;
        };
        defer dir.close();

        var iter = dir.iterate();
        const res: ?[]const u8 = while (try iter.next()) |entry| {
            if (entry.kind == .file and std.mem.eql(u8, entry.name, arg)) {
                break entry.name;
            }
        } else null;

        if (res != null) {
            try stdout.print("{s} is {s}/{s}\n", .{ arg, res.?, arg });
            return;
        }
    }

    try stdout.print("{s}: not found\n", .{arg});
}

fn handleEcho(input: []u8) !void {
    try stdout.print("{s}\n", .{input[5..]});
}

fn handleUnknownCommands(input: []u8) !void {
    try stdout.print("{s}: command not found\n", .{input});
}
