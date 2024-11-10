const std = @import("std");
const rl = @import("raylib");

pub const Button = struct {
    rect: rl.Rectangle,
    text: [*:0]const u8,
    is_hovered: bool,

    pub fn init(x: f32, y: f32, width: f32, height: f32, button_text: [*:0]const u8) Button {
        return Button{
            .rect = rl.Rectangle{
                .x = x,
                .y = y,
                .width = width,
                .height = height,
            },
            .text = button_text,
            .is_hovered = false,
        };
    }

    pub fn update(self: *Button, mouse_pos: rl.Vector2) void {
        self.is_hovered = rl.checkCollisionPointRec(mouse_pos, self.rect);
    }

    pub fn draw(self: Button) void {
        const button_color = if (self.is_hovered) rl.Color.gray else rl.Color.red;
        rl.drawRectangleRec(self.rect, button_color);
        rl.drawRectangleLinesEx(self.rect, 2, rl.Color.black);

        const text_width = rl.measureText(self.text, 20);
        const text_x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2;
        const text_y = self.rect.y + (self.rect.height - 20) / 2;
        rl.drawText(self.text, @intFromFloat(text_x), @intFromFloat(text_y), 20, rl.Color.black);
    }

    pub fn isClicked(self: Button) bool {
        return self.is_hovered and rl.isMouseButtonPressed(.mouse_button_left);
    }
};
