const std = @import("std");
const execute = @import("execute.zig");

const stdout = std.io.getStdOut().writer();

pub fn handler(input: []u8) !void {
    var iter = std.mem.splitSequence(u8, input, " ");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var args = std.ArrayList([]const u8).init(allocator);
    defer {
        args.deinit();
        const status = gpa.deinit();
        if (status == .leak) {
            stdout.print("memory leak\n", .{}) catch {};
            std.process.exit(100);
        }
    }

    if (iter.next()) |command| {
        try args.append(command);
        while (iter.next()) |arg| {
            try args.append(arg);
        }

        if (std.mem.eql(u8, command, "exit")) {
            handleExit(args.items);
        } else if (std.mem.eql(u8, command, "echo")) {
            try handleEcho(args.items);
        } else if (std.mem.eql(u8, command, "type")) {
            try handleType(args.items);
        } else if (std.mem.eql(u8, command, "pwd")) {
            const buffer = try allocator.alloc(u8, 1000);
            defer allocator.free(buffer);
            const result = try std.fs.cwd().realpath(".", buffer);
            try stdout.print("{s}\n", .{result});
        } else {
            try handleUnknownCommands(args.items);
        }
    } else {
        std.process.exit(1);
    }
}

fn handleExit(args: [][]const u8) void {
    if (args.len > 1) {
        const exitCode = args[1];
        const intExitCode = std.fmt.parseInt(u8, exitCode, 10) catch 5;
        std.process.exit(intExitCode);
    } else std.process.exit(6);
}

fn handleType(args: [][]const u8) !void {
    const builtins = [_][]const u8{ "echo", "type", "exit" };
    if (args.len <= 1) {
        return;
    }

    var idx: u32 = 1;

    while (idx < args.len) : (idx += 1) {
        const arg = args[idx];

        const isBuiltin = for (builtins) |builtin| {
            if (std.mem.eql(u8, builtin, arg)) {
                break true;
            }
        } else false;

        if (isBuiltin) {
            try stdout.print("{s} is a shell builtin\n", .{arg});
        } else if (idx == 1) {
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

fn handleEcho(args: [][]const u8) !void {
    if (args.len > 1) {
        for (args[1..], 1..) |arg, i| {
            try stdout.print("{s}{s}", .{ arg, if (i == args.len - 1) "" else " " });
        }
        try stdout.print("\n", .{});
    }
}

fn handleUnknownCommands(args: [][]const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            stdout.print("memory leak\n", .{}) catch {};
            std.process.exit(100);
        }
    }

    const allocator = gpa.allocator();

    if (args.len == 0) {
        return;
    }
    const command = args[0];

    if (try execute.findExecutableInPath(allocator, command)) |res| {
        defer allocator.free(res);
        try execute.executeExe(allocator, args);
    } else {
        try stdout.print("{s}: command not found\n", .{command});
    }
}
