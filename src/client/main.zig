const std = @import("std");
const rl = @import("raylib");
const Vector2 = rl.Vector2;

const Client = @import("network.zig").Client;

const Grid = @import("grid.zig").Grid;
const GridCoord = @import("grid.zig").GridCoord;

const Character = @import("character.zig").Character;
const CharacterType = @import("character.zig").CharacterType;
const Team = @import("character.zig").Team;

const hud = @import("hud.zig");

const GRID_X = 200;
const GRID_Y = 50;
const CELL_SIZE = 50;

const State = struct {
    phase: Phase,
    grid: Grid(i32),
    characters: std.ArrayList(Character),
    hoveredCell: ?GridCoord,
    selectedCharacter: ?*Character,
    characterMovePath: std.ArrayList(GridCoord),
};

const Phase = enum { Move, Default };

var state: State = undefined;

pub fn main() !void {
    //test networking
    var client = try Client.init("127.0.0.1", 8080);
    defer client.deinit();

    std.debug.print("Connected to server\n", .{});

    // Send a message
    const message = "Hello";
    try client.writeMessage(message);
    std.debug.print("Sent message: {s}\n", .{message});

    // Read response
    var buf: [128]u8 = undefined;
    const response = try client.readMessage(&buf);
    std.debug.print("Server response: {s}\n", .{response});
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1280;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "zonk");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    state = .{
        .phase = Phase.Default,
        .grid = try Grid(i32).init(allocator, 8, 8),
        .characters = std.ArrayList(Character).init(allocator),
        .hoveredCell = null,
        .selectedCharacter = null,
        .characterMovePath = std.ArrayList(GridCoord).init(allocator),
    };

    defer state.grid.deinit();
    defer state.characters.deinit();
    defer state.characterMovePath.deinit();

    // Set up checkered board
    for (0..8) |y| {
        for (0..8) |x| {
            state.grid.set(x, y, toI32((x + y) % 2));
        }
    }
    state.grid.print();

    // Set up characters
    try state.characters.append(Character.init(CharacterType.Warrior, 0, 0, Team.Red));
    try state.characters.append(Character.init(CharacterType.Warrior, 1, 1, Team.Blue));

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        try update();
        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        drawGrid(&state.grid);
        drawCharacters(&state.characters);
        drawHoveredCell(state.hoveredCell);
        if (state.selectedCharacter) |character| {
            hud.HUD.drawCharacterHUD(character, screenWidth, screenHeight);
        }

        //----------------------------------------------------------------------------------
    }
}

fn update() !void {
    const mousePos: Vector2 = rl.getMousePosition();
    if (calcGridCoord(&state.grid, std.math.lossyCast(usize, mousePos.x), std.math.lossyCast(usize, mousePos.y))) |coord| {
        // std.debug.print("cell x: {d}\n", .{coord.x});
        // std.debug.print("cell y: {d}\n", .{coord.y});
        state.hoveredCell = coord;
    } else {
        state.hoveredCell = null;
    }

    if (state.phase == Phase.Default) {
        if (rl.isMouseButtonPressed(.mouse_button_left)) {
            if (state.hoveredCell) |cell| {
                if (state.selectedCharacter) |character| {
                    state.characterMovePath.clearRetainingCapacity();
                    try findPath(&state.grid, &state.characterMovePath, character.x, character.y, cell.x, cell.y);
                    for (state.characterMovePath.items) |coord| {
                        std.debug.print("path coord\n", .{});
                        std.debug.print("path x: {d}\n", .{coord.x});
                        std.debug.print("path y: {d}\n", .{coord.y});
                    }
                    state.phase = Phase.Move;
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
    } else if (state.phase == Phase.Move) {
        if (state.characterMovePath.items.len > 0) {
            const coord = state.characterMovePath.pop();
            if (state.selectedCharacter) |character| {
                character.move(coord.x, coord.y);
            }
        } else {
            state.selectedCharacter = null;
            state.phase = Phase.Default;
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

const Node = struct {
    coord: GridCoord,
    f_score: f32, // total estimated cost
    g_score: f32, // cost from start
    parent: ?*Node,

    fn init(coord: GridCoord) Node {
        return .{
            .coord = coord,
            .f_score = std.math.inf(f32),
            .g_score = std.math.inf(f32),
            .parent = null,
        };
    }

    pub fn print(self: *const Node) void {
        std.debug.print("Node{{ x: {}, y: {}, f_score: {d:.2}, g_score: {d:.2} }}\n", .{
            self.coord.x,
            self.coord.y,
            self.f_score,
            self.g_score,
        });

        if (self.parent) |parent| {
            std.debug.print("  Parent: x={}, y={}\n", .{ parent.coord.x, parent.coord.y });
        } else {
            std.debug.print("  No parent (start node)\n", .{});
        }
    }
};

fn heuristic(a: GridCoord, b: GridCoord) f32 {
    const dx = @as(f32, @floatFromInt(@abs(@as(i32, @intCast(a.x)) - @as(i32, @intCast(b.x)))));
    const dy = @as(f32, @floatFromInt(@abs(@as(i32, @intCast(a.y)) - @as(i32, @intCast(b.y)))));
    return dx + dy; // Manhattan distance
}

pub fn findPath(
    grid: *const Grid(i32),
    path: *std.ArrayList(GridCoord),
    startX: usize,
    startY: usize,
    endX: usize,
    endY: usize,
) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var queue: std.ArrayList(*Node) = std.ArrayList(*Node).init(allocator); // Nodes to explore
    var seen = std.AutoHashMap(GridCoord, void).init(allocator); // Already explored nodes
    const start = GridCoord{ .x = startX, .y = startY };
    const end = GridCoord{ .x = endX, .y = endY };

    var start_node = try allocator.create(Node);
    start_node.* = Node.init(start);
    start_node.g_score = 0;
    start_node.f_score = heuristic(start, end);

    try queue.append(start_node);

    while (queue.items.len > 0) {
        std.debug.print("---NEW CYCLE---\n", .{});
        std.debug.print("Queue length: {d}\n", .{queue.items.len});
        //find lowest f score
        var lowest_fscore = queue.items[0];
        var lowest_fscore_index: usize = 0;
        for (queue.items, 0..) |node, i| {
            if (node.f_score < lowest_fscore.f_score) {
                lowest_fscore = node;
                lowest_fscore_index = i;
            }
        }
        std.debug.print("Lowest f score: ", .{});
        lowest_fscore.print();

        if (lowest_fscore.coord.equals(end)) {
            var current: ?*Node = lowest_fscore;
            while (current) |node| {
                try path.append(node.coord);
                current = node.parent;
            }
            return;
        }

        try seen.put(lowest_fscore.coord, {});
        const removed_node = queue.swapRemove(lowest_fscore_index);
        std.debug.print("Removed node: ", .{});
        removed_node.print();

        const directions = [_][2]i32{
            .{ -1, 0 }, // left
            .{ 1, 0 }, // right
            .{ 0, -1 }, // up
            .{ 0, 1 }, // down
        };

        for (directions) |dir| {
            const newX = toI32(lowest_fscore.coord.x) + dir[0];
            const newY = toI32(lowest_fscore.coord.y) + dir[1];
            if (newX < 0 or newY < 0 or newX > grid.width or newY > grid.height) continue;
            const neighbor = GridCoord{ .x = @intCast(newX), .y = @intCast(newY) };
            if (!grid.isWithinBounds(neighbor)) continue;
            if (seen.contains(neighbor)) continue;

            var node = try allocator.create(Node);
            node.* = Node.init(neighbor);
            node.g_score = lowest_fscore.g_score + 1;
            node.f_score = heuristic(neighbor, end);
            node.parent = lowest_fscore;

            try queue.append(node);
        }
    }
}
