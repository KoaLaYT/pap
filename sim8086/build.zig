const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sim86_dep = b.dependency("sim86", .{});
    const sim86_lib = b.addStaticLibrary(.{
        .name = "sim86",
        .root_source_file = b.path("src/sim86.zig"),
        .target = target,
        .optimize = optimize,
    });
    sim86_lib.addCSourceFile(.{
        .file = sim86_dep.path("perfaware/sim86/sim86_lib.cpp"),
        .flags = &[_][]const u8{},
    });
    sim86_lib.linkLibCpp();

    const decode = b.addExecutable(.{
        .name = "dumpdecode",
        .root_source_file = b.path("src/decode.zig"),
        .target = target,
        .optimize = optimize,
    });
    decode.linkLibrary(sim86_lib);

    b.installArtifact(decode);
    b.installArtifact(sim86_lib);

    const decode_cmd = b.addRunArtifact(decode);

    decode_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        decode_cmd.addArgs(args);
    }

    const run_decode_step = b.step("decode", "Run the decode");
    run_decode_step.dependOn(&decode_cmd.step);

    const sim86_tests = b.addTest(.{
        .root_source_file = b.path("src/sim86_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    sim86_tests.linkLibrary(sim86_lib);
    const exec_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/exec.zig"),
        .target = target,
        .optimize = optimize,
    });
    exec_unit_tests.linkLibrary(sim86_lib);

    const run_exe_unit_tests = b.addRunArtifact(exec_unit_tests);
    const run_sim86_tests = b.addRunArtifact(sim86_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_sim86_tests.step);
}
