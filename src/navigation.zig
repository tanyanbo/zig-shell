const std = @import("std");

const Cwd = struct {
    cwd: [std.fs.max_path_bytes]u8 = undefined,
    len: usize = 0,

    pub fn setCwd(self: *Cwd, dir: []const u8) void {
        self.len = dir.len;
        std.mem.copyForwards(u8, &self.cwd, dir);
    }

    pub fn getCwd(self: *Cwd) []u8 {
        return self.cwd[0..self.len];
    }
};

pub var cwd = Cwd{};
