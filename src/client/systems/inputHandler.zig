const rl = @import("raylib");
const Vector2 = rl.Vector2;

pub const InputState = struct {
    // Mouse state
    mouse_pos: Vector2,
    mouse_pressed: bool,
    mouse_clicked: bool,

    pub fn init() InputState {
        return .{
            .mouse_pos = .{ .x = 0, .y = 0 },
            .mouse_pressed = false,
            .mouse_clicked = false,
        };
    }

    pub fn update(self: *InputState) void {
        // Update mouse state
        self.mouse_pos = rl.getMousePosition();
        const mouse_down = rl.isMouseButtonDown(.mouse_button_left);
        self.mouse_clicked = !self.mouse_pressed and mouse_down;
        self.mouse_pressed = mouse_down;
    }
};
