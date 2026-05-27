const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = .Both,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const mod = b.addModule("rubix", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const desktop_mod = b.addModule("rubix_desktop", .{
        .root_source_file = b.path("src/desktop.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "rubix", .module = mod },
            .{ .name = "raylib", .module = raylib },
        },
    });

    const exe = b.addExecutable(.{
        .name = "rubix",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "rubix", .module = mod },
                .{ .name = "raylib", .module = raylib },
            },
        }),
    });

    const cli_exe = b.addExecutable(.{
        .name = "rubix-cli",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cli.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "rubix", .module = mod },
            },
        }),
    });

    exe.root_module.linkLibrary(raylib_artifact);
    b.installArtifact(exe);
    b.installArtifact(cli_exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_step.dependOn(&run_cmd.step);

    const cli_step = b.step("cli", "Run the CLI");
    const cli_cmd = b.addRunArtifact(cli_exe);
    cli_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        cli_cmd.addArgs(args);
    }
    cli_step.dependOn(&cli_cmd.step);

    const test_step = b.step("test", "Run tests");
    addRunTest(test_step, b.addTest(.{ .root_module = mod }), b);
    addRunTest(test_step, b.addTest(.{ .root_module = exe.root_module }), b);
    addRunTest(test_step, b.addTest(.{ .root_module = cli_exe.root_module }), b);
    addRunTest(test_step, addTestFile(b, mod, target, optimize, "test/cube_test.zig"), b);
    addRunTest(test_step, addTestFile(b, mod, target, optimize, "test/cli_test.zig"), b);
    addRunTest(test_step, addDesktopTestFile(b, mod, desktop_mod, target, optimize, "test/camera_test.zig"), b);
    addRunTest(test_step, addDesktopTestFile(b, mod, desktop_mod, target, optimize, "test/controls_test.zig"), b);
    addRunTest(test_step, addTestFile(b, mod, target, optimize, "test/animation_test.zig"), b);
    addRunTest(test_step, addTestFile(b, mod, target, optimize, "test/facelet_test.zig"), b);
    addRunTest(test_step, addTestFile(b, mod, target, optimize, "test/move_test.zig"), b);
    addRunTest(test_step, addTestFile(b, mod, target, optimize, "test/scramble_test.zig"), b);
    addRunTest(test_step, addTestFile(b, mod, target, optimize, "test/notation_test.zig"), b);
    addRunTest(test_step, addTestFile(b, mod, target, optimize, "test/ui_test.zig"), b);
}

fn addTestFile(
    b: *std.Build,
    mod: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    path: []const u8,
) *std.Build.Step.Compile {
    return b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "rubix", .module = mod },
            },
        }),
    });
}

fn addDesktopTestFile(
    b: *std.Build,
    mod: *std.Build.Module,
    desktop_mod: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    path: []const u8,
) *std.Build.Step.Compile {
    return b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "rubix", .module = mod },
                .{ .name = "rubix_desktop", .module = desktop_mod },
            },
        }),
    });
}

fn addRunTest(
    test_step: *std.Build.Step,
    compile_step: *std.Build.Step.Compile,
    b: *std.Build,
) void {
    const run_step = b.addRunArtifact(compile_step);
    test_step.dependOn(&run_step.step);
}
