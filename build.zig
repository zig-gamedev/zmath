const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const options = .{
        .optimize = b.option(
            std.builtin.OptimizeMode,
            "optimize",
            "The optimization level to use for the build",
        ) orelse .ReleaseFast,
        .enable_cross_platform_determinism = b.option(
            bool,
            "enable_cross_platform_determinism",
            "Enable cross-platform determinism",
        ) orelse true,
    };

    const options_step = b.addOptions();
    inline for (std.meta.fields(@TypeOf(options))) |field| {
        options_step.addOption(field.type, field.name, @field(options, field.name));
    }

    const options_module = options_step.createModule();

    const zmath = b.addModule("root", .{
        .root_source_file = b.path("src/root.zig"),
        .imports = &.{
            .{ .name = "zmath_options", .module = options_module },
        },
    });

    const test_step = b.step("test", "Run zmath tests");

    const tests = b.addTest(.{
        .name = "zmath-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = options.optimize,
        }),
    });
    b.installArtifact(tests);

    tests.root_module.addImport("zmath_options", options_module);

    test_step.dependOn(&b.addRunArtifact(tests).step);

    const benchmark_step = b.step("benchmark", "Run zmath benchmarks");

    const benchmarks = b.addExecutable(.{
        .name = "zmath-benchmarks",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/benchmark.zig"),
            .target = target,
            .optimize = options.optimize,
        }),
    });
    b.installArtifact(benchmarks);

    benchmarks.root_module.addImport("zmath", zmath);

    benchmark_step.dependOn(&b.addRunArtifact(benchmarks).step);
}
