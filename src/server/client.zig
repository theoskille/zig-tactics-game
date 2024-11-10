const std = @import("std");
const posix = std.posix;

const Reader = @import("reader.zig").Reader;

pub const Client = struct {
    socket: posix.socket_t,
    address: std.net.Address,

    pub fn handle(self: Client) void {
        self._handle() catch |err| switch (err) {
            error.Closed => {},
            else => std.debug.print("[{any}] client handle error: {}\n", .{ self.address, err }),
        };
    }

    fn _handle(self: Client) !void {
        const socket = self.socket;

        defer posix.close(socket);
        std.debug.print("{} connected\n", .{self.address});

        var buf: [1024]u8 = undefined;
        var reader = Reader{
            .pos = 0,
            .buf = &buf,
            .socket = socket,
        };

        while (true) {
            const msg = reader.readMessage() catch |err| {
                std.debug.print("Error reading from socket: {}\n", .{err});
                continue;
            };

            std.debug.print("Received message: {s}\n", .{msg});
        }
    }
};
