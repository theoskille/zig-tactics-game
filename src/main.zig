const std = @import("std");
const rl = @import("raylib");
const Vector2 = rl.Vector2;

const Grid = @import("grid.zig").Grid;
const GridCoord = @import("grid.zig").GridCoord;

const Character = @import("character.zig").Character;
const CharacterType = @import("character.zig").CharacterType;
const Team = @import("character.zig").Team;

const GRID_X = 20;
const GRID_Y = 20;
const CELL_SIZE = 50;

const State = struct {
    grid: Grid(i32),
    characters: std.ArrayList(Character),
    hoveredCell: ?GridCoord,
    selectedCharacter: ?*Character,
};

var state: State = undefined;

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "zonk");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    state = .{
        .grid = try Grid(i32).init(allocator, 8, 8),
        .characters = std.ArrayList(Character).init(allocator),
        .hoveredCell = null,
        .selectedCharacter = null,
    };

    defer state.grid.deinit();
    defer state.characters.deinit();

    // Set up checkered board
    for (0..8) |y| {
        for (0..8) |x| {
            state.grid.set(x, y, toI32((x + y) % 2));
        }
    }
    state.grid.print();

    // Set up characters
    try state.characters.append(Character.init(CharacterType.Warrior, 0, 0, Team.Red));
    try state.characters.append(Character.init(CharacterType.Archer, 1, 1, Team.Blue));

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        update();
        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        drawGrid(&state.grid);
        drawCharacters(&state.characters);
        drawHoveredCell(state.hoveredCell);

        //----------------------------------------------------------------------------------
    }
}

fn update() void {
    const mousePos: Vector2 = rl.getMousePosition();
    if (calcGridCoord(&state.grid, std.math.lossyCast(usize, mousePos.x), std.math.lossyCast(usize, mousePos.y))) |coord| {
        // std.debug.print("cell x: {d}\n", .{coord.x});
        // std.debug.print("cell y: {d}\n", .{coord.y});
        state.hoveredCell = coord;
    } else {
        state.hoveredCell = null;
    }

    if (rl.isMouseButtonPressed(.mouse_button_left)) {
        if (state.hoveredCell) |cell| {
            if (state.selectedCharacter) |character| {
                character.move(cell.x, cell.y);
                std.debug.print("moved character\n", .{});
                state.selectedCharacter = null;
            } else {
                for (state.characters.items) |*character| {
                    if (character.x == cell.x and character.y == cell.y) {
                        state.selectedCharacter = character;
                        std.debug.print("selected character\n", .{});
                    }
                }
            }
        }
    }
}

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

// Utility Functions
//----------------------------------------------------------------------------------

fn toI32(value: anytype) i32 {
    return @as(i32, @intCast(value));
}

// Render Functions
//----------------------------------------------------------------------------------
fn drawGrid(grid: *const Grid(i32)) void {
    for (0..grid.height) |y| {
        for (0..grid.width) |x| {
            const value = grid.get(x, y);
            const color = switch (value) {
                0 => rl.Color.white,
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
