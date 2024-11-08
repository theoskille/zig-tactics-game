const std = @import("std");
const GridCoord = @import("grid.zig").GridCoord;

pub const CharacterType = enum {
    Warrior,
    Archer,
    Mage,
    Rogue,
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

    pub fn init(char_type: CharacterType, x: usize, y: usize, team: Team) Character {
        return .{
            .type = char_type,
            .x = x,
            .y = y,
            .team = team,
        };
    }

    pub fn move(self: *Character, new_x: usize, new_y: usize) void {
        self.x = new_x;
        self.y = new_y;
    }
};
