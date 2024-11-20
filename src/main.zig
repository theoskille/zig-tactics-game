const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
    @cInclude("stdlib.h");
});

pub fn main() !void {
    ray.InitWindow(800, 450, "Raylib + Zig");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    const allocator = std.heap.c_allocator;
    // Allocate memory using C allocator
    const buffer = try allocator.alloc(u8, 100000);
    defer allocator.free(buffer);

    // Use the buffer
    @memset(buffer, 'A');

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.RAYWHITE);
        ray.DrawText("Memory Test", 190, 200, 20, ray.BLACK);
    }
}
