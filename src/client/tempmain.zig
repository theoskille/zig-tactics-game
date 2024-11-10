const std = @import("std");
const rl = @import("raylib");
const Vector2 = rl.Vector2;

const GameClient = @import("client.zig").GameClient;

const Grid = @import("grid.zig").Grid;
const GridCoord = @import("grid.zig").GridCoord;

const Character = @import("character.zig").Character;
const CharacterType = @import("character.zig").CharacterType;
const Team = @import("character.zig").Team;

const hud = @import("hud.zig");
const Button = @import("button.zig").Button;

pub fn main() !void {
    // Network
    const address = try std.net.Address.parseIp("127.0.0.1", 8080);
    var client = try GameClient.init(address);
    defer client.deinit();
    // Initialization
    //--------------------------------------------------------------------------------------
    //--------------------------------------------------------------------------------------

    //set up title screen buttons
    var play_button = Button.init((screenWidth - 100) / 2, screenHeight / 2 - 100 - 10, 200, 100, "Play Game\x00");
    var search_button = Button.init((screenWidth - 100) / 2, screenHeight / 2 - 300 - 10, 200, 100, "Search for Game\x00");

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();
        if (state.phase == Phase.Title_screen) {
            play_button.update(rl.getMousePosition());
            search_button.update(rl.getMousePosition());
            if (play_button.isClicked()) {
                state.phase = Phase.Default;
                std.debug.print("Play button clicked\n", .{});
            }
            if (search_button.isClicked()) {
                try client.searchGame();
                std.debug.print("Search button clicked\n", .{});
            }
            rl.clearBackground(rl.Color.white);
            play_button.draw();
            search_button.draw();
        }
    }
}

// Utility Functions
//----------------------------------------------------------------------------------

// Render Functions
//----------------------------------------------------------------------------------
