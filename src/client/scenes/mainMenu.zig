const std = @import("std");
const rl = @import("raylib");
const Vector2 = rl.Vector2;
const InputState = @import("../systems/inputHandler.zig").InputState;
const Button = @import("../ui/button.zig").Button;

pub const MainMenu = struct {
    inputState: InputState,
    play_button: Button,
    search_button: Button,

    pub fn init() !MainMenu {
        const play_button = Button.init((1280 - 100) / 2, 720 / 2 - 100 - 10, 200, 100, "Play Game\x00");
        const search_button = Button.init((1280 - 100) / 2, 720 / 2 - 300 - 10, 200, 100, "Search for Game\x00");
        return .{
            .inputState = InputState.init(),
            .play_button = play_button,
            .search_button = search_button,
        };
    }

    pub fn update(self: *MainMenu) !void {
        self.inputState.update();
        self.play_button.update(self.inputState.mouse_pos);
        self.search_button.update(self.inputState.mouse_pos);
        if (self.play_button.isClicked()) {
            std.debug.print("Play button clicked\n", .{});
        }
        if (self.search_button.isClicked()) {
            std.debug.print("Search button clicked\n", .{});
        }
    }

    pub fn render(self: *MainMenu) !void {
        rl.clearBackground(rl.Color.white);
        self.play_button.draw();
        self.search_button.draw();
    }
};
