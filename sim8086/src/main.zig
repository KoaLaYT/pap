const std = @import("std");
const Allocator = std.mem.Allocator;
const stdout = std.io.getStdOut().writer();

const REG_TABLE: [2][8][]const u8 = .{
    .{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" }, // W = 0
    .{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" }, // W = 1
};

const EFFECTIVE_ADDRESS_TABLE: [2][8][]const u8 = .{
    .{ "bx + si", "bx + di", "bp + si", "bp + di", "si", "di", "", "bx" }, // MOD = 00
    .{ "bx + si", "bx + di", "bp + si", "bp + di", "si", "di", "bp", "bx" }, // MOD = 01 | 10
};

pub fn main() !void {
    var it = std.process.args();
    _ = it.next();
    const bin_file = it.next().?;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const bin = try readBin(allocator, bin_file);
    defer allocator.free(bin);

    var i: usize = 0;
    while (i < bin.len) {
        i += try doParse(bin[i..]);
    }
}

fn doParse(bin: []const u8) !usize {
    const b1 = bin[0];

    if ((b1 >> 4) == 0b1011) {
        return try parseMOVImmToReg(bin);
    } else if ((b1 >> 2) == 0b100010) {
        return try parseMov(bin);
    } else if ((b1 >> 1) == 0b1100011) {
        return try parseMovImmToRegOrMem(bin);
    } else if ((b1 >> 1) == 0b1010000) {
        return try parseMovMemToAcc(bin);
    } else if ((b1 >> 1) == 0b1010001) {
        return try parseMovAccToMem(bin);
    }

    return error.UnknownOpcode;
}

fn parseMovAccToMem(bin: []const u8) !usize {
    const b1 = bin[0];
    const w: u1 = @intCast(b1 & 0b1);

    var data: i16 = 0;
    var len: usize = 0;

    if (w == 0) {
        data = bin[1];
        len = 2;
    } else {
        data = std.mem.readInt(i16, &.{ bin[1], bin[2] }, .little);
        len = 3;
    }

    try stdout.print("mov [{}], ax\n", .{data});
    return len;
}

fn parseMovMemToAcc(bin: []const u8) !usize {
    const b1 = bin[0];
    const w: u1 = @intCast(b1 & 0b1);

    var data: i16 = 0;
    var len: usize = 0;

    if (w == 0) {
        data = bin[1];
        len = 2;
    } else {
        data = std.mem.readInt(i16, &.{ bin[1], bin[2] }, .little);
        len = 3;
    }

    try stdout.print("mov ax, [{}]\n", .{data});
    return len;
}

fn parseMovImmToRegOrMem(bin: []const u8) !usize {
    const b1 = bin[0];
    const b2 = bin[1];

    const w: u1 = @intCast(b1 & 0b1);
    const mod: u2 = @intCast(b2 >> 6);
    const r_m: u3 = @intCast(b2 & 0b111);

    var buf: [32]u8 = undefined;
    var size_buf: [32]u8 = undefined;
    var effective_addr: []const u8 = undefined;
    var src: []const u8 = undefined;
    var dst: []const u8 = undefined;
    var len: usize = 0;

    if (mod == 0b11) {
        effective_addr = REG_TABLE[w][r_m];
        len = 2;
    }

    if (mod == 0b00) {
        std.debug.assert(r_m != 0b110);
        const regs = EFFECTIVE_ADDRESS_TABLE[0][r_m];
        effective_addr = try std.fmt.bufPrint(&buf, "[{s}]", .{regs});
        len = 2;
    }

    if (mod == 0b01) {
        const regs = EFFECTIVE_ADDRESS_TABLE[1][r_m];
        const data: i8 = @bitCast(bin[2]);
        const sign: u8 = if (data < 0) '-' else '+';
        effective_addr = try std.fmt.bufPrint(&buf, "[{s} {c} {}]", .{ regs, sign, @abs(data) });
        len = 3;
    }

    if (mod == 0b10) {
        const regs = EFFECTIVE_ADDRESS_TABLE[1][r_m];
        const data = std.mem.readInt(i16, &.{ bin[2], bin[3] }, .little);
        const sign: u8 = if (data < 0) '-' else '+';
        effective_addr = try std.fmt.bufPrint(&buf, "[{s} {c} {}]", .{ regs, sign, @abs(data) });
        len = 4;
    }

    if (w == 0) {
        const data = bin[len];
        src = try std.fmt.bufPrint(&size_buf, "byte {}", .{data});
        len += 1;
    } else {
        const data = std.mem.readInt(i16, &.{ bin[len], bin[len + 1] }, .little);
        src = try std.fmt.bufPrint(&size_buf, "word {}", .{data});
        len += 2;
    }

    dst = effective_addr;
    try stdout.print("mov {s}, {s}\n", .{ dst, src });
    return len;
}

fn parseMov(bin: []const u8) !usize {
    const b1 = bin[0];
    const b2 = bin[1];

    const d: u1 = @intCast((b1 >> 1) & 0b1);
    const w: u1 = @intCast(b1 & 0b1);
    const mod: u2 = @intCast(b2 >> 6);
    const reg: u3 = @intCast((b2 >> 3) & 0b111);
    const r_m: u3 = @intCast(b2 & 0b111);

    var buf: [32]u8 = undefined;
    var effective_addr: []const u8 = undefined;
    var src: []const u8 = undefined;
    var dst: []const u8 = undefined;
    var len: usize = 0;

    if (mod == 0b11) {
        effective_addr = REG_TABLE[w][r_m];
        len = 2;
    }

    if (mod == 0b00) {
        if (r_m == 0b110) {
            const data = std.mem.readInt(i16, &.{ bin[2], bin[3] }, .little);
            effective_addr = try std.fmt.bufPrint(&buf, "[{}]", .{data});
            len = 4;
        } else {
            const regs = EFFECTIVE_ADDRESS_TABLE[0][r_m];
            effective_addr = try std.fmt.bufPrint(&buf, "[{s}]", .{regs});
            len = 2;
        }
    }

    if (mod == 0b01) {
        const regs = EFFECTIVE_ADDRESS_TABLE[1][r_m];
        const data: i8 = @bitCast(bin[2]);
        const sign: u8 = if (data < 0) '-' else '+';
        effective_addr = try std.fmt.bufPrint(&buf, "[{s} {c} {}]", .{ regs, sign, @abs(data) });
        len = 3;
    }

    if (mod == 0b10) {
        const regs = EFFECTIVE_ADDRESS_TABLE[1][r_m];
        const data = std.mem.readInt(i16, &.{ bin[2], bin[3] }, .little);
        const sign: u8 = if (data < 0) '-' else '+';
        effective_addr = try std.fmt.bufPrint(&buf, "[{s} {c} {}]", .{ regs, sign, @abs(data) });
        len = 4;
    }

    if (d == 0) {
        src = REG_TABLE[w][reg];
        dst = effective_addr;
    } else {
        dst = REG_TABLE[w][reg];
        src = effective_addr;
    }

    try stdout.print("mov {s}, {s}\n", .{ dst, src });
    return len;
}

fn parseMOVImmToReg(bin: []const u8) !usize {
    const b1 = bin[0];
    const w: u1 = @intCast((b1 & 0b00001000) >> 3);
    const reg: u3 = @intCast(b1 & 0b111);
    var data: i16 = 0;
    var len: usize = 0;
    if (w == 1) {
        data = std.mem.readInt(i16, &.{ bin[1], bin[2] }, .little);
        len = 3;
    } else {
        data = bin[1];
        len = 2;
    }
    try stdout.print("mov {s}, {}\n", .{ REG_TABLE[w][reg], data });
    return len;
}

fn readBin(allocator: Allocator, bin_file: []const u8) ![]u8 {
    const f = try std.fs.cwd().openFile(bin_file, .{});
    defer f.close();

    return f.readToEndAlloc(allocator, 4096);
}
