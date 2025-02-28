const std = @import("std");
const Allocator = std.mem.Allocator;
const sim86 = @import("sim86.zig");

//  0 {},
//  1 {"al", "ah", "ax"},
//  2 {"bl", "bh", "bx"},
//  3 {"cl", "ch", "cx"},
//  4 {"dl", "dh", "dx"},
//  5 {"sp", "sp", "sp"},
//  6 {"bp", "bp", "bp"},
//  7 {"si", "si", "si"},
//  8 {"di", "di", "di"},
//  9 {"es", "es", "es"},
// 10 {"cs", "cs", "cs"},
// 11 {"ss", "ss", "ss"},
// 12 {"ds", "ds", "ds"},
// 13 {"ip", "ip", "ip"},
const REGISTERS = 14;

const Registers = struct {
    data: [REGISTERS * 2]u8,

    const Self = @This();

    fn init() Self {
        var data: [REGISTERS * 2]u8 = undefined;
        @memset(&data, 0);
        return .{
            .data = data,
        };
    }

    fn update(self: *Self, at: sim86.RegisterAccess, v: u16) void {
        std.debug.assert(at.Index < REGISTERS);

        const lo: u8 = @intCast(v & 0xFF);
        const hi: u8 = @intCast(v >> 8);

        if (at.Count == 2) {
            self.data[at.Index * 2] = lo;
            self.data[at.Index * 2 + 1] = hi;
        } else if (at.Offset == 0) {
            std.debug.assert(hi == 0);
            self.data[at.Index * 2] = lo;
        } else if (at.Offset == 1) {
            std.debug.assert(hi == 0);
            self.data[at.Index * 2 + 1] = lo;
        } else {
            unreachable;
        }
    }

    fn get(self: Self, at: sim86.RegisterAccess) u16 {
        std.debug.assert(at.Index < REGISTERS);

        if (at.Count == 2) {
            return std.mem.readInt(u16, &.{ self.data[at.Index * 2], self.data[at.Index * 2 + 1] }, .little);
        } else if (at.Offset == 0) {
            return self.data[at.Index * 2];
        } else if (at.Offset == 1) {
            return self.data[at.Index * 2 + 1];
        } else {
            unreachable;
        }
    }
};

const Cpu = struct {
    registers: Registers,

    const Self = @This();

    fn init() Self {
        const registers = Registers.init();
        return .{ .registers = registers };
    }

    fn exec(self: *Self, source: []u8) !void {
        var idx: usize = 0;
        while (idx < source.len) {
            const inst = try sim86.decode8086Instruction(source[idx..]);
            self.execOne(inst);
            idx += inst.Size;
        }
    }

    fn execOne(self: *Self, inst: sim86.Instruction) void {
        const dst = inst.Operands[0];
        const src = inst.Operands[1];

        if (dst.Type == .OperandRegister and src.Type == .OperandImmediate) {
            const v: u16 = @intCast(src.data.Immediate.Value);
            self.registers.update(dst.data.Register, v);
        } else if (dst.Type == .OperandRegister and src.Type == .OperandRegister) {
            const v = self.registers.get(src.data.Register);
            self.registers.update(dst.data.Register, v);
        } else {
            unreachable;
        }
    }
};

fn readBin(allocator: Allocator, bin_file: []const u8) ![]u8 {
    const f = try std.fs.cwd().openFile(bin_file, .{});
    defer f.close();

    return f.readToEndAlloc(allocator, 4096);
}

const testing = std.testing;

test {
    const allocator = testing.allocator;

    const TestCase = struct {
        input_file: []const u8,
        expect: []const u16,
    };

    const test_cases = [_]TestCase{
        .{
            .input_file = "asm/immediate_movs",
            .expect = &.{ 1, 2, 3, 4, 5, 6, 7, 8, 0, 0, 0, 0, 0 },
        },
        .{
            .input_file = "asm/register_movs",
            .expect = &.{ 4, 3, 2, 1, 1, 2, 3, 4, 0, 0, 0, 0, 0 },
        },
    };

    for (test_cases) |tt| {
        const bin = try readBin(allocator, tt.input_file);
        defer allocator.free(bin);

        var cpu = Cpu.init();
        try cpu.exec(bin);

        for (1..REGISTERS) |i| {
            const at = sim86.RegisterAccess{ .Index = @intCast(i), .Offset = 0, .Count = 2 };
            const value = cpu.registers.get(at);
            try testing.expectEqual(tt.expect[i - 1], value);
        }
    }
}
