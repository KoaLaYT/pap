const std = @import("std");
const Allocator = std.mem.Allocator;
const sim86 = @import("sim86.zig");

pub fn main() !void {
    var it = std.process.args();
    _ = it.next();
    const bin_file = it.next().?;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const bin = try readBin(allocator, bin_file);
    defer allocator.free(bin);

    var idx: usize = 0;
    while (idx < bin.len) {
        const inst = try sim86.decode8086Instruction(bin[idx..]);

        inst.debug();
        std.debug.print("\n", .{});

        idx += inst.Size;
    }
}

fn readBin(allocator: Allocator, bin_file: []const u8) ![]u8 {
    const f = try std.fs.cwd().openFile(bin_file, .{});
    defer f.close();

    return f.readToEndAlloc(allocator, 4096);
}
