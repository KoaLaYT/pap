const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn readBin(allocator: Allocator, bin_file: []const u8) ![]u8 {
    const f = try std.fs.cwd().openFile(bin_file, .{});
    defer f.close();

    return f.readToEndAlloc(allocator, 4096);
}
