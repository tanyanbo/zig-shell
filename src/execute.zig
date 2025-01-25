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

pub fn executeExe(allocator: std.mem.Allocator, args: [][]const u8) !void {
    var child = std.process.Child.init(args, allocator);
    _ = try child.spawnAndWait();
}

pub fn isExecutable(mode: u32) bool {
    return mode & 0b001 != 0;
}
