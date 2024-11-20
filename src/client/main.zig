const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const MainMenu = @import("scenes/mainMenu.zig").MainMenu;
const Game = @import("scenes/game.zig").Game;
const GameClient = @import("net/client.zig").GameClient;
const Vector2 = rl.Vector2;

const Scene = enum {
    MainMenu,
    Game,
};

pub fn main() !void {
    const screenWidth = 1280;
    const screenHeight = 720;

    rl.InitWindow(screenWidth, screenHeight, "Zig Tactics");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    const allocator = std.heap.c_allocator;

    //connect to server
    // const address = try std.net.Address.parseIp("127.0.0.1", 8080);
    // var client = try GameClient.init(address);
    // defer client.deinit();
    // try client.searchGame();
    // Initialize scenes
    var main_menu = try MainMenu.init();

    var game = try Game.init(allocator);
    defer game.deinit();

    try game.state.generateState();

    const currentScene = Scene.Game;

    // Main game loop
    while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
        rl.BeginDrawing();
        defer rl.EndDrawing();

        switch (currentScene) {
            Scene.MainMenu => {
                try main_menu.update();
                try main_menu.render();
            },
            Scene.Game => {
                try game.update();
                try game.render();
            },
        }
    }
}
