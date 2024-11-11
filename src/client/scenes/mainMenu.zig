const std = @import("std");
const rl = @import("raylib");
const Vector2 = rl.Vector2;
const GameClient = @import("../net/client.zig").GameClient;
const InputState = @import("../systems/inputHandler.zig").InputState;
const Button = @import("../ui/button.zig").Button;
const Text = @import("../ui/text.zig").Text;

pub const MainMenu = struct {
    inputState: InputState,
    play_button: Button,
    search_button: Button,
    searching_text: Text,
    searching: bool,
    client: GameClient,

    pub fn init(client: GameClient) !MainMenu {
        const play_button = Button.init((1280 - 100) / 2, 720 / 2 - 100 - 10, 200, 100, "Play Game\x00");
        const search_button = Button.init((1280 - 100) / 2, 720 / 2 - 300 - 10, 200, 100, "Search for Game\x00");
        return .{
            .inputState = InputState.init(),
            .play_button = play_button,
            .search_button = search_button,
            .searching_text = Text.init(1280 / 2 - 100, 720 / 2 - 100, 200, 100, "Searching for game...\x00"),
            .searching = false,
            .client = client,
        };
    }

    pub fn update(self: *MainMenu) !void {
        if (self.searching) {} else {
            self.inputState.update();
            self.play_button.update(self.inputState.mouse_pos);
            self.search_button.update(self.inputState.mouse_pos);
            if (self.play_button.isClicked()) {
                std.debug.print("Play button clicked\n", .{});
            }
            if (self.search_button.isClicked()) {
                std.debug.print("Search button clicked\n", .{});
                self.searching = true;
                try self.client.searchGame();
            }
        }
    }

    pub fn render(self: *MainMenu) !void {
        rl.clearBackground(rl.Color.white);
        if (self.searching) {
            self.searching_text.draw();
        } else {
            self.play_button.draw();
            self.search_button.draw();
        }
    }
};
