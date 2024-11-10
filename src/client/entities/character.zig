const std = @import("std");
const GridCoord = @import("grid.zig").GridCoord;

pub const CharacterType = enum {
    Warrior,
};

pub const AbilityType = enum {
    MeleeAttack,
    RangedAttack,
    Fireball,
};

pub const Team = enum {
    Red,
    Blue,
};

pub const Character = struct {
    type: CharacterType,
    x: usize,
    y: usize,
    team: Team,
    health: u32,
    max_health: u32,
    abilities: [1]Ability,

    pub fn init(char_type: CharacterType, x: usize, y: usize, team: Team) Character {
        const abilities = switch (char_type) {
            .Warrior => [1]Ability{
                .{
                    .type = .MeleeAttack,
                    .range = 1,
                    .damage = 20,
                    .cooldown = 1,
                },
            },
        };
        return .{
            .type = char_type,
            .x = x,
            .y = y,
            .team = team,
            .health = 100,
            .max_health = 100,
            .abilities = abilities,
        };
    }

    pub fn move(self: *Character, new_x: usize, new_y: usize) void {
        self.x = new_x;
        self.y = new_y;
    }
};

pub const Ability = struct {
    type: AbilityType,
    range: usize,
    damage: ?u32,
    cooldown: u32,

    pub fn use(self: Ability) void {
        // Implementation would go here

        std.debug.print("Using ability: {}\n", .{self.type});
    }
};
