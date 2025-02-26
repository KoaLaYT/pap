const std = @import("std");
const Allocator = std.mem.Allocator;
const stdout = std.io.getStdOut().writer();

const REG_TABLE: [2][8][]const u8 = .{
    .{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" }, // W = 0
    .{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" }, // W = 1
};

const OP_MOV: u6 = 0b100010;

pub fn main() !void {
    var it = std.process.args();
    _ = it.next();
    const bin_file = it.next().?;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const bin = try readBin(allocator, bin_file);
    defer allocator.free(bin);

    std.debug.assert(bin.len % 2 == 0);

    var i: usize = 0;
    while (i < bin.len) : (i += 2) {
        try parseMOV(bin[i], bin[i + 1]);
    }
}

fn parseMOV(b1: u8, b2: u8) !void {
    const op: u6 = @intCast(b1 >> 2);
    const d: u1 = @intCast((b1 >> 1) & 0b1);
    const w: u1 = @intCast(b1 & 0b1);
    const mod: u2 = @intCast(b2 >> 6);
    const reg: u3 = @intCast((b2 >> 3) & 0b111);
    const r_m: u3 = @intCast(b2 & 0b111);

    if (op != OP_MOV or mod != 0b11) {
        return error.BadInput;
    }

    var src: []const u8 = undefined;
    var dst: []const u8 = undefined;
    if (d == 0) {
        src = REG_TABLE[w][reg];
        dst = REG_TABLE[w][r_m];
    } else {
        dst = REG_TABLE[w][reg];
        src = REG_TABLE[w][r_m];
    }

    try stdout.print("mov {s}, {s}\n", .{ dst, src });
}

fn readBin(allocator: Allocator, bin_file: []const u8) ![]u8 {
    const f = try std.fs.cwd().openFile(bin_file, .{});
    defer f.close();

    return f.readToEndAlloc(allocator, 4096);
}
