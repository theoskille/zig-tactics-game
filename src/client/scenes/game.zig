const std = @import("std");
const State = @import("../game/state.zig").State;
const Phase = @import("../game/state.zig").Phase;
const GridCoord = @import("../entities/grid.zig").GridCoord;
const Grid = @import("../entities/grid.zig").Grid;
const Character = @import("../entities/character.zig").Character;
const Team = @import("../entities/character.zig").Team;
const toI32 = @import("../utility/utils.zig").toI32;
const InputState = @import("../systems/inputHandler.zig").InputState;
const findPath = @import("../systems/astar.zig").findPath;
const hud = @import("../ui/hud.zig");
const Button = @import("../ui/button.zig").Button;
const rl = @import("raylib");
const Vector2 = rl.Vector2;

const GRID_X = 200;
const GRID_Y = 50;
const CELL_SIZE = 50;

pub const Game = struct {
    allocator: std.mem.Allocator,
    inputState: InputState,
    state: State,
    hoveredCell: ?GridCoord,
    selectedCharacter: ?*Character,
    characterMovePath: std.ArrayList(GridCoord),

    pub fn init(allocator: std.mem.Allocator) !Game {
        return .{
            .allocator = allocator,
            .inputState = InputState.init(),
            .state = try State.init(allocator),
            .hoveredCell = null,
            .selectedCharacter = null,
            .characterMovePath = std.ArrayList(GridCoord).init(allocator),
        };
    }

    pub fn deinit(self: *Game) void {
        self.state.deinit();
        self.characterMovePath.deinit();
    }

    pub fn update(self: *Game) !void {
        self.inputState.update();

        if (calcGridCoord(&self.state.grid, std.math.lossyCast(usize, self.inputState.mouse_pos.x), std.math.lossyCast(usize, self.inputState.mouse_pos.y))) |coord| {
            self.hoveredCell = coord;
        } else {
            self.hoveredCell = null;
        }

        switch (self.state.phase) {
            Phase.Default => {
                if (self.inputState.mouse_clicked) {
                    if (self.hoveredCell) |cell| {
                        if (self.selectedCharacter) |character| {
                            self.characterMovePath.clearRetainingCapacity();
                            try findPath(&self.state.grid, &self.characterMovePath, character.x, character.y, cell.x, cell.y);
                            // for (self.state.characterMovePath.items) |coord| {
                            //     std.debug.print("path coord\n", .{});
                            //     std.debug.print("path x: {d}\n", .{coord.x});
                            //     std.debug.print("path y: {d}\n", .{coord.y});
                            // }
                            self.state.phase = Phase.Move;
                        } else {
                            for (self.state.characters.items) |*character| {
                                if (character.x == cell.x and character.y == cell.y) {
                                    self.selectedCharacter = character;
                                    std.debug.print("selected character\n", .{});
                                }
                            }
                        }
                    }
                }
            },
            Phase.Move => {
                if (self.characterMovePath.items.len > 0) {
                    const coord = self.characterMovePath.pop();
                    if (self.selectedCharacter) |character| {
                        character.move(coord.x, coord.y);
                    }
                } else {
                    self.selectedCharacter = null;
                    self.state.phase = Phase.Default;
                }
            },
        }
    }

    pub fn render(self: *Game) !void {
        rl.clearBackground(rl.Color.white);

        drawGrid(&self.state.grid);
        drawCharacters(&self.state.characters);
        drawHoveredCell(self.hoveredCell);
        if (self.selectedCharacter) |character| {
            hud.HUD.drawCharacterHUD(character, 1280, 720);
        }
    }
};

//helper functions
fn calcGridCoord(grid: *const Grid(i32), mousePosX: usize, mousePosY: usize) ?GridCoord {
    //check if mouse is within grid
    if (mousePosX > GRID_X and mousePosX < GRID_X + grid.width * CELL_SIZE and
        mousePosY > GRID_Y and mousePosY < GRID_Y + grid.height * CELL_SIZE)
    {
        //calculate cell clicked
        const cellX = (mousePosX - GRID_X) / CELL_SIZE;
        const cellY = (mousePosY - GRID_Y) / CELL_SIZE;
        return GridCoord{ .x = cellX, .y = cellY };
    }
    // std.debug.print("mouse out of bounds\n", .{});
    return null;
}

// render functions

fn drawGrid(grid: *const Grid(i32)) void {
    for (0..grid.height) |y| {
        for (0..grid.width) |x| {
            const value = grid.get(x, y);
            const color = switch (value) {
                0 => rl.Color.gray,
                1 => rl.Color.black,
                else => rl.Color.gray,
            };
            rl.drawRectangle(toI32(x * CELL_SIZE + GRID_X), toI32(y * CELL_SIZE + GRID_Y), toI32(CELL_SIZE), toI32(CELL_SIZE), color);
        }
    }
}

fn drawCharacters(characters: *const std.ArrayList(Character)) void {
    for (characters.items) |character| {
        const color = switch (character.team) {
            Team.Red => rl.Color.red,
            Team.Blue => rl.Color.blue,
        };
        rl.drawCircle(toI32(character.x * CELL_SIZE + GRID_X + CELL_SIZE / 2), toI32(character.y * CELL_SIZE + GRID_Y + CELL_SIZE / 2), 10, color);
    }
}

fn drawHoveredCell(hoveredCell: ?GridCoord) void {
    if (hoveredCell) |cell| {
        const x = toI32(cell.x * CELL_SIZE + GRID_X);
        const y = toI32(cell.y * CELL_SIZE + GRID_Y);
        rl.drawRectangle(x, y, CELL_SIZE, CELL_SIZE, rl.Color.green);
    }
}
