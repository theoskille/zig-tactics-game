const std = @import("std");
const GridCoord = @import("../entities/grid.zig").GridCoord;
const Grid = @import("../entities/grid.zig").Grid;
const toI32 = @import("../utility/utils.zig").toI32;

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
