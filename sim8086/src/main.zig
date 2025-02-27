const std = @import("std");
const Allocator = std.mem.Allocator;
const stdout = std.io.getStdOut().writer();

const REG_TABLE: [2][8][]const u8 = .{
    .{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" }, // W = 0
    .{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" }, // W = 1
};
const EFFECTIVE_ADDRESS_TABLE: [8][]const u8 =
    .{ "bx + si", "bx + di", "bp + si", "bp + di", "si", "di", "bp", "bx" }; // MOD = 00 | 01 | 10
const JUMP_TABLE: [16][]const u8 = .{ "jo", "jno", "jb", "jnb", "je", "jne", "jbe", "jnbe", "js", "jns", "jp", "jnp", "jl", "jnl", "jle", "jnle" };
const LOOP_TABLE: [4][]const u8 = .{ "loopnz", "loopz", "loop", "jcxz" };

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
    const b2 = bin[1];

    if ((b1 >> 4) == 0b1011) {
        return try parseImmToReg("mov", bin);
    } else if ((b1 >> 2) == 0b100010) {
        return try parseRegMemWithReg("mov", bin);
    } else if ((b1 >> 1) == 0b1100011) {
        return try parseImmToRegOrMem("mov", bin);
    } else if ((b1 >> 1) == 0b1010000) {
        return try parseMovMemToAcc(bin);
    } else if ((b1 >> 1) == 0b1010001) {
        return try parseMovAccToMem(bin);
    } else if ((b1 >> 2) == 0b000000) {
        return try parseRegMemWithReg("add", bin);
    } else if ((b1 >> 2) == 0b100000 and ((b2 >> 3) & 0b111) == 0b000) {
        return try parseImmToRegOrMem("add", bin);
    } else if ((b1 >> 1) == 0b0000010) {
        return try parseImmToAcc("add", bin);
    } else if ((b1 >> 2) == 0b001010) {
        return try parseRegMemWithReg("sub", bin);
    } else if ((b1 >> 2) == 0b100000 and ((b2 >> 3) & 0b111) == 0b101) {
        return try parseImmToRegOrMem("sub", bin);
    } else if ((b1 >> 1) == 0b0010110) {
        return try parseImmToAcc("sub", bin);
    } else if ((b1 >> 2) == 0b001110) {
        return try parseRegMemWithReg("cmp", bin);
    } else if ((b1 >> 2) == 0b100000 and ((b2 >> 3) & 0b111) == 0b111) {
        return try parseImmToRegOrMem("cmp", bin);
    } else if ((b1 >> 1) == 0b0011110) {
        return try parseImmToAcc("cmp", bin);
    } else if ((b1 >> 4) == 0b0111) {
        const offset = b1 & 0b1111;
        return try parseJnzLike(JUMP_TABLE[offset], bin);
    } else if ((b1 >> 2) == 0b111000) {
        const offset = b1 & 0b11;
        return try parseJnzLike(LOOP_TABLE[offset], bin);
    }

    return error.UnknownOpcode;
}

fn parseJnzLike(op: []const u8, bin: []const u8) !usize {
    const offset: i16 = @intCast(@as(i8, @bitCast(bin[1])));

    if (offset + 2 > 0) {
        try stdout.print("{s} $+{}+0\n", .{ op, offset + 2 });
    } else if (offset + 2 == 0) {
        try stdout.print("{s} $+0\n", .{op});
    } else {
        try stdout.print("{s} ${}+0\n", .{ op, offset + 2 });
    }

    return 2;
}

fn parseMovAccToMem(bin: []const u8) !usize {
    const b1 = bin[0];
    const w: u1 = @intCast(b1 & 0b1);

    var data: i16 = 0;
    var len: usize = 0;

    if (w == 0) {
        data = bin[1];
        try stdout.print("mov [{}], al\n", .{data});
        len = 2;
    } else {
        data = std.mem.readInt(i16, &.{ bin[1], bin[2] }, .little);
        try stdout.print("mov [{}], ax\n", .{data});
        len = 3;
    }

    return len;
}

fn parseImmToAcc(op: []const u8, bin: []const u8) !usize {
    const b1 = bin[0];
    const w: u1 = @intCast(b1 & 0b1);

    if (w == 0) {
        const data: i8 = @bitCast(bin[1]);
        try stdout.print("{s} al, {}\n", .{ op, data });
        return 2;
    } else {
        const data = std.mem.readInt(i16, &.{ bin[1], bin[2] }, .little);
        try stdout.print("{s} ax, {}\n", .{ op, data });
        return 3;
    }
}

fn parseMovMemToAcc(bin: []const u8) !usize {
    const b1 = bin[0];
    const w: u1 = @intCast(b1 & 0b1);

    var data: i16 = 0;
    var len: usize = 0;

    if (w == 0) {
        data = bin[1];
        len = 2;
        try stdout.print("mov al, [{}]\n", .{data});
    } else {
        data = std.mem.readInt(i16, &.{ bin[1], bin[2] }, .little);
        len = 3;
        try stdout.print("mov ax, [{}]\n", .{data});
    }

    return len;
}

fn parseMod(bin: []const u8, buf: []u8, mod: u2, s: u1, w: u1, r_m: u3) !struct { []const u8, usize } {
    var effective_addr: []const u8 = undefined;
    var len: usize = 0;

    if (mod == 0b11) {
        effective_addr = REG_TABLE[w][r_m];
        len = 2;
    } else if (mod == 0b00) {
        if (r_m == 0b110) {
            const data = std.mem.readInt(i16, &.{ bin[2], bin[3] }, .little);
            effective_addr = try std.fmt.bufPrint(buf, "[{}]", .{data});
            len = 4;
        } else {
            const regs = EFFECTIVE_ADDRESS_TABLE[r_m];
            effective_addr = try std.fmt.bufPrint(buf, "[{s}]", .{regs});
            len = 2;
        }
    } else if (mod == 0b01) {
        const regs = EFFECTIVE_ADDRESS_TABLE[r_m];
        if (s == 1) {
            const data: i8 = @bitCast(bin[2]);
            const sign: u8 = if (data < 0) '-' else '+';
            effective_addr = try std.fmt.bufPrint(buf, "[{s} {c} {}]", .{ regs, sign, @abs(data) });
        } else {
            const data: u8 = bin[2];
            effective_addr = try std.fmt.bufPrint(buf, "[{s} + {}]", .{ regs, data });
        }
        len = 3;
    } else if (mod == 0b10) {
        const regs = EFFECTIVE_ADDRESS_TABLE[r_m];
        if (s == 1) {
            const data = std.mem.readInt(i16, &.{ bin[2], bin[3] }, .little);
            const sign: u8 = if (data < 0) '-' else '+';
            effective_addr = try std.fmt.bufPrint(buf, "[{s} {c} {}]", .{ regs, sign, @abs(data) });
        } else {
            const data = std.mem.readInt(u16, &.{ bin[2], bin[3] }, .little);
            effective_addr = try std.fmt.bufPrint(buf, "[{s} + {}]", .{ regs, data });
        }
        len = 4;
    }

    return .{ effective_addr, len };
}

fn parseImmToRegOrMem(op: []const u8, bin: []const u8) !usize {
    const b1 = bin[0];
    const b2 = bin[1];

    const s: u1 = @intCast((b1 >> 1) & 0b1);
    const w: u1 = @intCast(b1 & 0b1);
    const mod: u2 = @intCast(b2 >> 6);
    const r_m: u3 = @intCast(b2 & 0b111);

    var buf: [32]u8 = undefined;
    var size_buf: [32]u8 = undefined;
    var effective_addr: []const u8 = undefined;
    var src: []const u8 = undefined;
    var dst: []const u8 = undefined;
    var len: usize = 0;

    effective_addr, len = try parseMod(bin, &buf, mod, s, w, r_m);

    if ((s == 0 and w == 1) or (std.mem.eql(u8, op, "mov") and w == 1)) {
        const data = std.mem.readInt(i16, &.{ bin[len], bin[len + 1] }, .little);
        src = try std.fmt.bufPrint(&size_buf, "word {}", .{data});
        len += 2;
    } else if (w == 1) {
        const data = bin[len];
        src = try std.fmt.bufPrint(&size_buf, "word {}", .{data});
        len += 1;
    } else {
        const data = bin[len];
        src = try std.fmt.bufPrint(&size_buf, "byte {}", .{data});
        len += 1;
    }

    dst = effective_addr;
    try stdout.print("{s} {s}, {s}\n", .{ op, dst, src });
    return len;
}

fn parseRegMemWithReg(op: []const u8, bin: []const u8) !usize {
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

    effective_addr, len = try parseMod(bin, &buf, mod, 1, w, r_m);

    if (d == 0) {
        src = REG_TABLE[w][reg];
        dst = effective_addr;
    } else {
        dst = REG_TABLE[w][reg];
        src = effective_addr;
    }

    try stdout.print("{s} {s}, {s}\n", .{ op, dst, src });
    return len;
}

fn parseImmToReg(op: []const u8, bin: []const u8) !usize {
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
    try stdout.print("{s} {s}, {}\n", .{ op, REG_TABLE[w][reg], data });
    return len;
}

fn readBin(allocator: Allocator, bin_file: []const u8) ![]u8 {
    const f = try std.fs.cwd().openFile(bin_file, .{});
    defer f.close();

    return f.readToEndAlloc(allocator, 4096);
}
