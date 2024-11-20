const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

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
        self.is_hovered = rl.CheckCollisionPointRec(mouse_pos, self.rect);
    }

    pub fn draw(self: Button) void {
        const button_color = if (self.is_hovered) rl.GRAY else rl.RED;
        rl.DrawRectangleRec(self.rect, button_color);
        rl.DrawRectangleLinesEx(self.rect, 2, rl.BLACK);

        const text_width = rl.MeasureText(self.text, 20);
        const text_x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2;
        const text_y = self.rect.y + (self.rect.height - 20) / 2;
        rl.DrawText(self.text, @intFromFloat(text_x), @intFromFloat(text_y), 20, rl.BLACK);
    }

    pub fn isClicked(self: Button) bool {
        return self.is_hovered and rl.IsMouseButtonPressed(rl.MOUSE_LEFT_BUTTON);
    }
};
