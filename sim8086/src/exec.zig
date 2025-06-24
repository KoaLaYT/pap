const std = @import("std");
const sim86 = @import("sim86.zig");
const util = @import("util.zig");

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

const Memory = struct {
    data: [65536]u8,

    const Self = @This();

    fn init() Self {
        var data: [65536]u8 = undefined;
        @memset(&data, 0);
        return .{
            .data = data,
        };
    }

    fn store(self: *Self, offset: usize, v: u16) void {
        const lo: u8 = @intCast(v & 0xFF);
        const hi: u8 = @intCast(v >> 8);
        self.data[offset] = lo;
        self.data[offset + 1] = hi;
    }

    fn load(self: *Self, offset: usize) u16 {
        return std.mem.readInt(u16, &.{ self.data[offset], self.data[offset + 1] }, .little);
    }
};

const Flags = struct {
    // !! This layout is not equal to 8086's manual
    data: std.bit_set.IntegerBitSet(16),

    const Self = @This();

    fn init() Self {
        return .{
            .data = std.bit_set.IntegerBitSet(16).initEmpty(),
        };
    }

    fn setZero(self: *Self) void {
        self.data.set(0);
    }

    fn clearZero(self: *Self) void {
        self.data.unset(0);
    }

    fn isZero(self: Self) bool {
        return self.data.isSet(0);
    }

    fn setSign(self: *Self) void {
        self.data.set(1);
    }

    fn clearSign(self: *Self) void {
        self.data.unset(1);
    }

    fn isSign(self: Self) bool {
        return self.data.isSet(1);
    }
};

const Cpu = struct {
    registers: Registers,
    memory: Memory,
    flags: Flags,
    ip: usize,

    const Self = @This();

    fn init() Self {
        return .{
            .registers = Registers.init(),
            .memory = Memory.init(),
            .flags = Flags.init(),
            .ip = 0,
        };
    }

    fn exec(self: *Self, source: []u8) !void {
        var gpa = std.heap.DebugAllocator(.{}).init;
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        var instructions = std.AutoHashMap(usize, sim86.Instruction).init(allocator);
        defer instructions.deinit();

        var idx: usize = 0;
        while (idx < source.len) {
            const inst = try sim86.decode8086Instruction(source[idx..]);
            try instructions.put(idx, inst);
            idx += inst.Size;
        }

        while (self.ip < source.len) {
            const inst = instructions.get(self.ip) orelse unreachable;
            self.ip += inst.Size;
            self.execOne(inst);
        }
    }

    fn execOne(self: *Self, inst: sim86.Instruction) void {
        switch (inst.Op) {
            .Op_mov => self.execMov(inst),
            .Op_add => self.execAdd(inst),
            .Op_sub => self.execSub(inst),
            .Op_cmp => self.execCmp(inst),
            .Op_jne => self.execJne(inst),
            else => unreachable,
        }
    }

    fn setFlags(self: *Self, v: u16) void {
        if (v == 0) {
            self.flags.setZero();
        } else {
            self.flags.clearZero();
        }

        const iv: i16 = @bitCast(v);
        if (iv < 0) {
            self.flags.setSign();
        } else {
            self.flags.clearSign();
        }
    }

    fn execJne(self: *Self, inst: sim86.Instruction) void {
        const op = inst.Operands[0];
        if (op.Type != .OperandImmediate) {
            unreachable;
        }

        if (!self.flags.isZero()) {
            const v = op.data.Immediate.Value;
            if (v < 0) {
                self.ip -= @abs(v);
            } else {
                self.ip += @intCast(v);
            }
        }
    }

    fn execCmp(self: *Self, inst: sim86.Instruction) void {
        const dst = inst.Operands[0];
        const src = inst.Operands[1];

        if (dst.Type != .OperandRegister) {
            unreachable;
        }

        var v: u16 = undefined;
        if (src.Type == .OperandRegister) {
            v = self.registers.get(src.data.Register);
        } else if (src.Type == .OperandImmediate) {
            v = @intCast(src.data.Immediate.Value);
        } else {
            unreachable;
        }

        v = self.registers.get(dst.data.Register) -% v;
        self.setFlags(v);
    }

    fn execSub(self: *Self, inst: sim86.Instruction) void {
        const dst = inst.Operands[0];
        const src = inst.Operands[1];

        if (dst.Type != .OperandRegister) {
            unreachable;
        }

        var v: u16 = undefined;
        if (src.Type == .OperandRegister) {
            v = self.registers.get(src.data.Register);
        } else if (src.Type == .OperandImmediate) {
            v = @intCast(src.data.Immediate.Value);
        } else {
            unreachable;
        }

        v = self.registers.get(dst.data.Register) -% v;
        self.registers.update(dst.data.Register, v);
        self.setFlags(v);
    }

    fn execAdd(self: *Self, inst: sim86.Instruction) void {
        const dst = inst.Operands[0];
        const src = inst.Operands[1];

        if (dst.Type != .OperandRegister) {
            unreachable;
        }

        var v: u16 = undefined;
        if (src.Type == .OperandRegister) {
            v = self.registers.get(src.data.Register);
        } else if (src.Type == .OperandImmediate) {
            v = @intCast(src.data.Immediate.Value);
        } else {
            unreachable;
        }

        v = self.registers.get(dst.data.Register) +% v;
        self.registers.update(dst.data.Register, v);
        self.setFlags(v);
    }

    fn execMov(self: *Self, inst: sim86.Instruction) void {
        const dst = inst.Operands[0];
        const src = inst.Operands[1];
        if (dst.Type == .OperandRegister and src.Type == .OperandImmediate) {
            const v: u16 = @intCast(src.data.Immediate.Value);
            self.registers.update(dst.data.Register, v);
        } else if (dst.Type == .OperandRegister and src.Type == .OperandRegister) {
            const v = self.registers.get(src.data.Register);
            self.registers.update(dst.data.Register, v);
        } else if (dst.Type == .OperandMemory and src.Type == .OperandImmediate) {
            const v: u16 = @intCast(src.data.Immediate.Value);
            const offset = self.parseMemoryAddressExp(dst.data.Address);
            self.memory.store(offset, v);
        } else if (dst.Type == .OperandRegister and src.Type == .OperandMemory) {
            const offset = self.parseMemoryAddressExp(src.data.Address);
            const v = self.memory.load(offset);
            self.registers.update(dst.data.Register, v);
        } else if (dst.Type == .OperandMemory and src.Type == .OperandRegister) {
            const v = self.registers.get(src.data.Register);
            const offset = self.parseMemoryAddressExp(dst.data.Address);
            self.memory.store(offset, v);
        } else {
            std.debug.panic("unknown instruction {}\n", .{inst});
        }
    }

    fn parseMemoryAddressExp(self: *Self, address: sim86.EffectiveAddressExpression) usize {
        if (address.Terms[0].Register.Index == 0 and address.Terms[1].Register.Index == 0) {
            return @intCast(address.Displacement);
        } else if (address.Terms[0].Register.Index > 0 and address.Terms[1].Register.Index == 0) {
            const offset: i32 = @intCast(self.registers.get(address.Terms[0].Register));
            return @intCast(offset + address.Displacement);
        } else if (address.Terms[0].Register.Index > 0 and address.Terms[1].Register.Index > 0) {
            const offset1 = self.registers.get(address.Terms[0].Register);
            const offset2 = self.registers.get(address.Terms[1].Register);
            return offset1 + offset2;
        } else {
            std.debug.panic("{} {}\n", .{ address.Terms[0], address.Terms[1] });
        }
    }
};

const testing = std.testing;

test {
    const allocator = testing.allocator;

    const TestCase = struct {
        input_file: []const u8,
        expectRegisters: []const u16,
        expectZero: bool,
        expectSign: bool,
    };

    const test_cases = [_]TestCase{
        .{
            .input_file = "asm/0043_immediate_movs",
            .expectRegisters = &.{ 1, 2, 3, 4, 5, 6, 7, 8, 0, 0, 0, 0, 0 },
            .expectZero = false,
            .expectSign = false,
        },
        .{
            .input_file = "asm/0044_register_movs",
            .expectRegisters = &.{ 4, 3, 2, 1, 1, 2, 3, 4, 0, 0, 0, 0, 0 },
            .expectZero = false,
            .expectSign = false,
        },
        .{
            .input_file = "asm/0045_challenge_register_movs",
            .expectRegisters = &.{ 17425, 13124, 26231, 30600, 17425, 13124, 26231, 30600, 26231, 0, 17425, 13124, 0 },
            .expectZero = false,
            .expectSign = false,
        },
        .{
            .input_file = "asm/0046_add_sub_cmp",
            .expectRegisters = &.{ 0, 57602, 3841, 0, 998, 0, 0, 0, 0, 0, 0, 0, 0 },
            .expectZero = true,
            .expectSign = false,
        },
        .{
            .input_file = "asm/0048_ip_register",
            .expectRegisters = &.{ 0, 2000, 64736, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            .expectZero = false,
            .expectSign = true,
        },
        .{
            .input_file = "asm/0049_conditional_jumps",
            .expectRegisters = &.{ 0, 1030, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            .expectZero = true,
            .expectSign = false,
        },
        .{
            .input_file = "asm/0051_memory_mov",
            .expectRegisters = &.{ 0, 1, 2, 10, 0, 4, 0, 0, 0, 0, 0, 0, 0 },
            .expectZero = false,
            .expectSign = false,
        },
        .{
            .input_file = "asm/0052_memory_add_loop",
            .expectRegisters = &.{ 0, 6, 4, 6, 0, 1000, 6, 0, 0, 0, 0, 0, 0 },
            .expectZero = true,
            .expectSign = false,
        },
        .{
            .input_file = "asm/0054_draw_rectangle",
            .expectRegisters = &.{ 0, 0, 64, 64, 0, 16640, 0, 0, 0, 0, 0, 0, 0 },
            .expectZero = true,
            .expectSign = false,
        },
    };

    for (test_cases) |tt| {
        const bin = try util.readBin(allocator, tt.input_file);
        defer allocator.free(bin);

        var cpu = Cpu.init();
        try cpu.exec(bin);

        // check registers
        for (1..REGISTERS) |i| {
            const at = sim86.RegisterAccess{ .Index = @intCast(i), .Offset = 0, .Count = 2 };
            const value = cpu.registers.get(at);
            try testing.expectEqual(tt.expectRegisters[i - 1], value);
        }

        // check zero flags
        try testing.expectEqual(tt.expectZero, cpu.flags.isZero());

        // check sign flags
        try testing.expectEqual(tt.expectSign, cpu.flags.isSign());
    }
}
