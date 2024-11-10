const std = @import("std");
const posix = std.posix;

pub const MessageType = enum(u16) {
    // System: 0-999
    ping = 0,
    pong = 1,
    server_error = 2,

    // Matchmaking: 1000-1999
    search_game = 1000,
    game_found = 1001,
    cancel_search = 1002,

    // Game State: 2000-2999
    game_start = 2000,
    turn_start = 2001,
    turn_end = 2002,

    // Actions: 3000-3999
    move_unit = 3000,
    attack = 3001,

    _,
};

pub const Message = struct {
    type: MessageType,
    payload: []const u8,

    pub fn format(
        self: Message,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Message{{ type: {}, payload_len: {} }}", .{
            self.type,
            self.payload.len,
        });
    }
};
