const std = @import("std");
const posix = std.posix;

pub const Frame = struct {
    fin: bool,
    opcode: u4,
    mask: bool,
    payload_length: u64,
    mask_key: ?[4]u8,
    payload: []u8,
};

pub const MessageType = enum(u16) {
    // Matchmaking: 1000-1999
    search_game = 1000,
    game_found = 1001,

    // Actions: 3000-3999
    move_unit = 3000,
};

pub const Message = struct {
    type: MessageType,
    payload: []const u8,
};

// =========payload structs==============
pub const MoveUnitPayload = struct {
    id: usize, // 8 bytes
    x: usize, // 8 bytes
    y: usize, // 8 bytes

    // Convert from bytes to struct
    pub fn fromBytes(bytes: []const u8) !MoveUnitPayload {
        if (bytes.len < 24) return error.InvalidPayloadSize;
        return .{
            .id = std.mem.readInt(usize, bytes[0..8], .little),
            .x = std.mem.readInt(usize, bytes[8..16], .little),
            .y = std.mem.readInt(usize, bytes[16..24], .little),
        };
    }

    // Convert struct to bytes (useful for sending messages)
    pub fn toBytes(self: MoveUnitPayload) [24]u8 {
        var bytes: [24]u8 = undefined;
        std.mem.writeInt(usize, bytes[0..8], self.id, .little);
        std.mem.writeInt(usize, bytes[8..16], self.x, .little);
        std.mem.writeInt(usize, bytes[16..24], self.y, .little);
        return bytes;
    }
};
