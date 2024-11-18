const std = @import("std");
const net = std.net;

pub const MessageType = enum(u16) {
    // Same as server enum
    search_game = 1000,
    game_found = 1001,
    cancel_search = 1002,
    // ... other types as needed
    _,
};

pub fn writeMessage(socket: std.net.Stream, msg_type: MessageType, payload: []const u8) !void {
    var header: [6]u8 = undefined;

    // Write total message length (type + payload) in first 4 bytes
    const total_len: u32 = @intCast(2 + payload.len); // 2 for type
    std.mem.writeInt(u32, header[0..4], total_len, .little);

    // Write message type in next 2 bytes
    std.mem.writeInt(u16, header[4..6], @intFromEnum(msg_type), .little);

    // Write header and payload
    try socket.writeAll(&header);
    try socket.writeAll(payload);
}

pub const GameClient = struct {
    socket: std.net.Stream,

    pub fn init(address: std.net.Address) !GameClient {
        const socket = try std.net.tcpConnectToAddress(address);
        std.debug.print("connected\n", .{});
        return GameClient{
            .socket = socket,
        };
    }

    pub fn deinit(self: *GameClient) void {
        self.socket.close();
    }

    pub fn searchGame(self: *GameClient) !void {
        // For now, empty payload for search_game
        try writeMessage(self.socket, .search_game, &[_]u8{});
    }
};
