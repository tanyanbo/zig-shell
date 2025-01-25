const std = @import("std");
const execute = @import("execute.zig");

const stdout = std.io.getStdOut().writer();

pub fn handler(input: []u8) !void {
    var iter = std.mem.splitSequence(u8, input, " ");

    if (iter.next()) |command| {
        if (std.mem.eql(u8, command, "exit")) {
            if (iter.next()) |exitCode| {
                const intExitCode = std.fmt.parseInt(u8, exitCode, 10) catch 5;
                std.process.exit(intExitCode);
            } else {
                std.process.exit(6);
            }
        } else if (std.mem.eql(u8, command, "echo")) {
            try handleEcho(input);
        } else if (std.mem.eql(u8, command, "type")) {
            try handleType(input);
        } else {
            try handleUnknownCommands(input);
        }
    } else {
        std.process.exit(1);
    }
}

fn handleType(input: []u8) !void {
    const builtins = [_][]const u8{ "echo", "type", "exit" };
    var argsIter = std.mem.splitSequence(u8, input[5..], " ");

    while (argsIter.next()) |arg| {
        const isBuiltin = for (builtins) |builtin| {
            if (std.mem.eql(u8, builtin, arg)) {
                break true;
            }
        } else false;
        if (isBuiltin) {
            try stdout.print("{s} is a shell builtin\n", .{arg});
        } else {
            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer {
                const status = gpa.deinit();
                if (status == .leak) {
                    stdout.print("memory leak\n", .{}) catch {};
                    std.process.exit(100);
                }
            }

            const allocator = gpa.allocator();
            if (try execute.findExecutableInPath(allocator, arg)) |dir| {
                defer allocator.free(dir);
                try stdout.print("{s} is {s}/{s}\n", .{ arg, dir, arg });
                return;
            }
            try stdout.print("{s}: not found\n", .{arg});
        }
    }
}

fn handleEcho(input: []u8) !void {
    try stdout.print("{s}\n", .{input[5..]});
}

fn handleUnknownCommands(input: []u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            stdout.print("memory leak\n", .{}) catch {};
            std.process.exit(100);
        }
    }

    const allocator = gpa.allocator();

    var iter = std.mem.splitSequence(u8, input, " ");
    const command = iter.next();
    if (command == null) {
        return;
    }

    if (try execute.findExecutableInPath(allocator, command.?)) |res| {
        defer allocator.free(res);
        try execute.executeExe(allocator, input);
    } else {
        try stdout.print("{s}: command not found\n", .{input});
    }
}
