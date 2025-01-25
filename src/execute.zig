const std = @import("std");

pub fn findExecutableInPath(allocator: std.mem.Allocator, executable: []const u8) !?[]const u8 {
    const pathValue = try std.process.getEnvVarOwned(allocator, "PATH");
    defer allocator.free(pathValue);

    var pathIter = std.mem.splitSequence(u8, pathValue, ":");
    while (pathIter.next()) |path| {
        var dir = std.fs.openDirAbsolute(path, .{ .iterate = true }) catch {
            continue;
        };
        defer dir.close();

        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            if (std.mem.eql(u8, entry.name, executable)) {
                const result = try allocator.alloc(u8, path.len);
                for (path, 0..) |c, idx| {
                    result[idx] = c;
                }
                return result;
            }
        }
    }

    return null;
}

pub fn executeExe(allocator: std.mem.Allocator, fullPath: []const u8, command: []const u8) !void {
    const file = try std.fs.openFileAbsolute(fullPath, .{});
    const fileMode = try file.mode();
    if (isExecutable(fileMode)) {
        var args = std.ArrayList([]const u8).init(allocator);

        var iter = std.mem.splitSequence(u8, command, " ");
        _ = iter.next();
        while (iter.next()) |arg| {
            try args.append(arg);
        }

        var child = std.process.Child.init(args.items, allocator);
        _ = try child.spawnAndWait();
    }
}

pub fn isExecutable(mode: u32) bool {
    std.debug.print("{b}\n", .{mode});
    return mode & 0b001 != 0;
}
