const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add raylib dependency
    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    // Create client executable
    const client = b.addExecutable(.{
        .name = "game-client",
        .root_source_file = b.path("src/client/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    client.linkLibrary(raylib_artifact);
    client.root_module.addImport("raylib", raylib);
    client.root_module.addImport("raygui", raygui);

    b.installArtifact(client);

    // Add run step
    const run_cmd = b.addRunArtifact(client);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the client");
    run_step.dependOn(&run_cmd.step);
}
