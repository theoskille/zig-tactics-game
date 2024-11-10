const std = @import("std");
const posix = std.posix;

const Reader = @import("networkActions.zig").Reader;
const writeMessage = @import("networkActions.zig").writeMessage;
const MatchMaker = @import("matchMaker.zig").MatchMaker;
const Message = @import("protocol.zig").Message;
const GameFoundPayload = @import("protocol.zig").GameFoundPayload;

pub const Client = struct {
    socket: posix.socket_t,
    address: std.net.Address,
    matchmaker: *MatchMaker,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, socket: posix.socket_t, address: std.net.Address, matchmaker: *MatchMaker) !*Client {
        const client = try allocator.create(Client);
        client.* = .{
            .allocator = allocator,
            .socket = socket,
            .address = address,
            .matchmaker = matchmaker,
        };
        return client;
    }

    pub fn deinit(self: *Client) void {
        posix.close(self.socket);
        self.allocator.destroy(self);
    }

    pub fn handle(self: *Client) void {
        self._handle() catch |err| {
            std.debug.print("[{any}] client handle error: {}\n", .{ self.address, err });
        };
    }

    fn _handle(self: *Client) !void {
        const socket = self.socket;

        defer self.deinit();
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

            std.debug.print("Received message: {}\n", .{msg});

            switch (msg.type) {
                .search_game => try self.handleSearchGame(msg),
                else => {
                    std.debug.print("Unknown message type: {}\n", .{msg.type});
                },
            }
        }
    }

    fn handleSearchGame(self: *Client, msg: Message) !void {
        std.debug.print("Handling Search Game...\n", .{});
        _ = msg;
        if (try self.matchmaker.addPlayer(self)) |opponent| {
            std.debug.print("Match found!\n", .{});
            const payload = GameFoundPayload{
                .opponent_id = @intFromPtr(opponent),
            };
            var payload_bytes: [@sizeOf(GameFoundPayload)]u8 = undefined;
            std.mem.writeInt(u64, &payload_bytes, payload.opponent_id, .little);
            try writeMessage(self.socket, .game_found, &payload_bytes);
            try writeMessage(opponent.socket, .game_found, &payload_bytes);
        }
    }
};
