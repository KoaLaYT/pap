const std = @import("std");
const sim86 = @import("sim86.zig");
const util = @import("util.zig");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input_file = args.next().?;
    const bin = try util.readBin(allocator, input_file);
    defer allocator.free(bin);

    var idx: usize = 0;
    while (idx < bin.len) {
        const inst = try sim86.decode8086Instruction(bin[idx..]);
        inst.debug();
        try stdout.print("\n", .{});
        idx += inst.Size;
    }
}
