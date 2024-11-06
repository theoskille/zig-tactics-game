const std = @import("std");
const Character = @import("character.zig").Character;

pub const GridCoord = struct {
    x: usize,
    y: usize,
};

pub fn Grid(comptime T: type) type {
    return struct {
        data: []T,
        width: usize,
        height: usize,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Self {
            const data = try allocator.alloc(T, width * height);
            @memset(data, std.mem.zeroes(T));
            return Self{
                .data = data,
                .width = width,
                .height = height,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        pub fn get(self: *const Self, x: usize, y: usize) T {
            return self.data[y * self.width + x];
        }

        pub fn set(self: *Self, x: usize, y: usize, value: T) void {
            self.data[y * self.width + x] = value;
        }

        pub fn print(self: *const Self) void {
            for (0..self.height) |y| {
                for (0..self.width) |x| {
                    std.debug.print("{} ", .{self.get(x, y)});
                }
                std.debug.print("\n", .{});
            }
        }
    };
}
