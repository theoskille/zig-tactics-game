const std = @import("std");
const rl = @import("raylib");

pub const Text = struct {
    text: [*:0]const u8,
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn init(x: f32, y: f32, width: f32, height: f32, text: [*:0]const u8) Text {
        return Text{
            .text = text,
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        };
    }

    pub fn draw(self: Text) void {
        rl.drawText(self.text, @intFromFloat(self.x), @intFromFloat(self.y), 20, rl.Color.black);
    }
};
