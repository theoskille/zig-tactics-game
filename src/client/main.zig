const std = @import("std");
const rl = @import("raylib");
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

    rl.initWindow(screenWidth, screenHeight, "Zig Tactics");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    //connect to server
    const address = try std.net.Address.parseIp("127.0.0.1", 8080);
    var client = try GameClient.init(address);
    defer client.deinit();

    // Initialize scenes
    var main_menu = try MainMenu.init(client);

    var game = try Game.init(allocator);
    defer game.deinit();

    try game.state.generateState();

    const currentScene = Scene.MainMenu;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

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
