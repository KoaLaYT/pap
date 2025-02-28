const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dump_decode = b.addExecutable(.{
        .name = "dumpdecode",
        .root_source_file = b.path("src/dump_decode.zig"),
        .target = target,
        .optimize = optimize,
    });

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

    b.installArtifact(dump_decode);
    b.installArtifact(sim86_lib);

    const dump_decode_cmd = b.addRunArtifact(dump_decode);

    dump_decode_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        dump_decode_cmd.addArgs(args);
    }

    const run_dump_decode_step = b.step("dumpdecode", "Run the dump decode");
    run_dump_decode_step.dependOn(&dump_decode_cmd.step);

    const sim86_tests = b.addTest(.{
        .root_source_file = b.path("src/sim86_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    sim86_tests.linkLibrary(sim86_lib);
    const exex_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/exec.zig"),
        .target = target,
        .optimize = optimize,
    });
    exex_unit_tests.linkLibrary(sim86_lib);

    const run_exe_unit_tests = b.addRunArtifact(exex_unit_tests);
    const run_sim86_tests = b.addRunArtifact(sim86_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_sim86_tests.step);
}
