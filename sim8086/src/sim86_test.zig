const std = @import("std");
const sim86 = @import("sim86.zig");

const example_disassembly = [_]u8{
    0x03,
    0x18,
    0x03,
    0x5E,
    0x00,
    0x83,
    0xC6,
    0x02,
    0x83,
    0xC5,
    0x02,
    0x83,
    0xC1,
    0x08,
    0x03,
    0x5E,
    0x00,
    0x03,
    0x4F,
    0x02,
    0x02,
    0x7A,
    0x04,
    0x03,
    0x7B,
    0x06,
    0x01,
    0x18,
    0x01,
    0x5E,
    0x00,
    0x01,
    0x5E,
    0x00,
    0x01,
    0x4F,
    0x02,
    0x00,
    0x7A,
    0x04,
    0x01,
    0x7B,
    0x06,
    0x80,
    0x07,
    0x22,
    0x83,
    0x82,
    0xE8,
    0x03,
    0x1D,
    0x03,
    0x46,
    0x00,
    0x02,
    0x00,
    0x01,
    0xD8,
    0x00,
    0xE0,
    0x05,
    0xE8,
    0x03,
    0x04,
    0xE2,
    0x04,
    0x09,
    0x2B,
    0x18,
    0x2B,
    0x5E,
    0x00,
    0x83,
    0xEE,
    0x02,
    0x83,
    0xED,
    0x02,
    0x83,
    0xE9,
    0x08,
    0x2B,
    0x5E,
    0x00,
    0x2B,
    0x4F,
    0x02,
    0x2A,
    0x7A,
    0x04,
    0x2B,
    0x7B,
    0x06,
    0x29,
    0x18,
    0x29,
    0x5E,
    0x00,
    0x29,
    0x5E,
    0x00,
    0x29,
    0x4F,
    0x02,
    0x28,
    0x7A,
    0x04,
    0x29,
    0x7B,
    0x06,
    0x80,
    0x2F,
    0x22,
    0x83,
    0x29,
    0x1D,
    0x2B,
    0x46,
    0x00,
    0x2A,
    0x00,
    0x29,
    0xD8,
    0x28,
    0xE0,
    0x2D,
    0xE8,
    0x03,
    0x2C,
    0xE2,
    0x2C,
    0x09,
    0x3B,
    0x18,
    0x3B,
    0x5E,
    0x00,
    0x83,
    0xFE,
    0x02,
    0x83,
    0xFD,
    0x02,
    0x83,
    0xF9,
    0x08,
    0x3B,
    0x5E,
    0x00,
    0x3B,
    0x4F,
    0x02,
    0x3A,
    0x7A,
    0x04,
    0x3B,
    0x7B,
    0x06,
    0x39,
    0x18,
    0x39,
    0x5E,
    0x00,
    0x39,
    0x5E,
    0x00,
    0x39,
    0x4F,
    0x02,
    0x38,
    0x7A,
    0x04,
    0x39,
    0x7B,
    0x06,
    0x80,
    0x3F,
    0x22,
    0x83,
    0x3E,
    0xE2,
    0x12,
    0x1D,
    0x3B,
    0x46,
    0x00,
    0x3A,
    0x00,
    0x39,
    0xD8,
    0x38,
    0xE0,
    0x3D,
    0xE8,
    0x03,
    0x3C,
    0xE2,
    0x3C,
    0x09,
    0x75,
    0x02,
    0x75,
    0xFC,
    0x75,
    0xFA,
    0x75,
    0xFC,
    0x74,
    0xFE,
    0x7C,
    0xFC,
    0x7E,
    0xFA,
    0x72,
    0xF8,
    0x76,
    0xF6,
    0x7A,
    0xF4,
    0x70,
    0xF2,
    0x78,
    0xF0,
    0x75,
    0xEE,
    0x7D,
    0xEC,
    0x7F,
    0xEA,
    0x73,
    0xE8,
    0x77,
    0xE6,
    0x7B,
    0xE4,
    0x71,
    0xE2,
    0x79,
    0xE0,
    0xE2,
    0xDE,
    0xE1,
    0xDC,
    0xE0,
    0xDA,
    0xE3,
    0xD8,
};

fn makeExampleDisassemblyCopy(allocator: std.mem.Allocator) ![]u8 {
    const copy = try allocator.alloc(u8, 247);
    @memcpy(copy, &example_disassembly);
    return copy;
}

test "sim86GetVersion" {
    try std.testing.expectEqual(4, sim86.getVersion());
}

test "get8086InstructionTable" {
    const table = sim86.get8086InstructionTable();
    try std.testing.expectEqual(133, table.EncodingCount);
}

test "decode8086Instruction/mnemonicFromOperationType" {
    const allocator = std.testing.allocator;

    const mem = try makeExampleDisassemblyCopy(allocator);
    defer allocator.free(mem);

    var decoded = try sim86.decode8086Instruction(mem);
    try std.testing.expectEqual(2, decoded.Size);
    try std.testing.expectEqual(sim86.InstructionFlag{ .Wide = true }, decoded.Flags);
    try std.testing.expectEqualStrings("add", sim86.mnemonicFromOperationType(decoded.Op));
    try std.testing.expectEqual(sim86.OperandType.OperandRegister, decoded.Operands[0].Type);
    try std.testing.expectEqualStrings("bx", sim86.registerNameFromOperand(&(decoded.Operands[0].data.Register)));
    try std.testing.expectEqual(sim86.OperandType.OperandMemory, decoded.Operands[1].Type);
}
