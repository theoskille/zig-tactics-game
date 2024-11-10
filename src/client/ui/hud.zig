const std = @import("std");
const rl = @import("raylib");

const Character = @import("../entities/character.zig").Character;

pub const HUD = struct {
    const ability_panel_height = 100;
    const stats_panel_width = 200;
    const padding = 10;
    const ability_box_size = 60;
    const text_size = 20;

    pub fn drawCharacterHUD(character: *const Character, window_width: i32, window_height: i32) void {
        // Draw bottom panel for abilities
        rl.drawRectangle(0, window_height - ability_panel_height, window_width, ability_panel_height, rl.Color{ .r = 40, .g = 40, .b = 40, .a = 230 });

        // Draw right panel for stats
        rl.drawRectangle(window_width - stats_panel_width, 0, stats_panel_width, window_height - ability_panel_height, rl.Color{ .r = 40, .g = 40, .b = 40, .a = 230 });

        // Draw character stats
        drawCharacterStats(character, window_width - stats_panel_width, 0);

        // Draw abilities
        drawAbilities(character, window_height);
    }

    fn drawCharacterStats(character: *const Character, x: i32, y: i32) void {
        const char_type_text = switch (character.type) {
            .Warrior => "Warrior",
        };

        const team_text = switch (character.team) {
            .Red => "Red Team",
            .Blue => "Blue Team",
        };

        // Draw character type and team
        rl.drawText(char_type_text, x + padding, y + padding, text_size, rl.Color.white);
        rl.drawText(team_text, x + padding, y + padding + text_size + 5, text_size, rl.Color.white);

        // Draw health bar
        const health_bar_width = stats_panel_width - (padding * 2);
        const health_bar_height = 20;
        const health_percentage = @as(f32, @floatFromInt(character.health)) / @as(f32, @floatFromInt(character.max_health));

        // Health bar background
        rl.drawRectangle(x + padding, y + padding + (text_size + 5) * 2, health_bar_width, health_bar_height, rl.Color.gray);

        // Health bar fill
        rl.drawRectangle(x + padding, y + padding + (text_size + 5) * 2, @as(i32, @intFromFloat(@as(f32, @floatFromInt(health_bar_width)) * health_percentage)), health_bar_height, rl.Color.red);

        // var health_text_buffer: [32]u8 = undefined;
        // const health_text = std.fmt.bufPrint(&health_text_buffer, "HP: {d}/{d}", .{ character.health, character.max_health }) catch |err| switch (err) {
        //     error.NoSpaceLeft => "HP: ERR",
        // };

        // rl.drawText(health_text_buffer[0..health_text.len].ptr, x + padding, y + padding + (text_size + 5) * 2 + health_bar_height + 5, text_size, rl.WHITE);
    }

    fn drawAbilities(character: *const Character, window_height: i32) void {
        const start_x = padding;
        const start_y = window_height - ability_panel_height + padding;

        // Draw each ability box
        for (character.abilities, 0..) |ability, i| {
            const box_x = start_x + @as(i32, @intCast(i)) * (ability_box_size + padding);
            const box_y = start_y;

            // Draw ability box background
            rl.drawRectangle(box_x, box_y, ability_box_size, ability_box_size, rl.Color.gray);

            // Draw ability name
            const ability_name = switch (ability.type) {
                .MeleeAttack => "Melee",
                .RangedAttack => "Range",
                .Fireball => "Fire",
            };

            rl.drawText(ability_name, box_x + 5, box_y + 5, 12, rl.Color.white);

            // // Draw ability stats
            // if (ability.damage) |dmg| {
            //     const dmg_text = std.fmt.allocPrint(std.heap.page_allocator, "DMG:{d}", .{dmg}) catch "DMG:??";
            //     defer if (dmg_text.len > 6) std.heap.page_allocator.free(dmg_text);

            //     rl.drawText(dmg_text.ptr, box_x + 5, box_y + 20, 12, rl.WHITE);
            // }

            // const range_text = std.fmt.allocPrint(std.heap.page_allocator, "RNG:{d}", .{ability.range}) catch "RNG:??";
            // defer if (range_text.len > 6) std.heap.page_allocator.free(range_text);

            // rl.drawText(range_text.ptr, box_x + 5, box_y + 35, 12, rl.WHITE);

            // const cd_text = std.fmt.allocPrint(std.heap.page_allocator, "CD:{d}", .{ability.cooldown}) catch "CD:??";
            // defer if (cd_text.len > 5) std.heap.page_allocator.free(cd_text);

            // rl.drawText(cd_text.ptr, box_x + 5, box_y + 50, 12, rl.WHITE);
        }
    }
};
