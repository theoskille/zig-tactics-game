const std = @import("std");

const Grid = @import("../entities/grid.zig").Grid;
const GridCoord = @import("../entities/grid.zig").GridCoord;
const Character = @import("../entities/character.zig").Character;
const CharacterType = @import("../entities/character.zig").CharacterType;
const Team = @import("../entities/character.zig").Team;
const toI32 = @import("../utility/utils.zig").toI32;

pub const Phase = enum { Move, Default };

pub const State = struct {
    phase: Phase,
    grid: Grid(i32),
    characters: std.ArrayList(Character),

    pub fn init(allocator: std.mem.Allocator) !State {
        return .{
            .phase = Phase.Default,
            .grid = try Grid(i32).init(allocator, 8, 8),
            .characters = std.ArrayList(Character).init(allocator),
        };
    }

    pub fn deinit(self: *State) void {
        self.grid.deinit();
        self.characters.deinit();
    }

    pub fn generateState(self: *State) !void {
        // Set up checkered board
        for (0..8) |y| {
            for (0..8) |x| {
                self.grid.set(x, y, toI32((x + y) % 2));
            }
        }

        // Set up characters
        try self.characters.append(Character.init(CharacterType.Warrior, 0, 0, Team.Red));
        try self.characters.append(Character.init(CharacterType.Warrior, 1, 1, Team.Blue));
    }

    //TODO add applyAction function
};
