const std = @import("std");
const posix = std.posix;
const Message = @import("protocol.zig").Message;
const MessageType = @import("protocol.zig").MessageType;
const Frame = @import("protocol.zig").Frame;

pub const Reader = struct {
    buf: []u8,
    pos: usize = 0,
    start: usize = 0,

    pub fn init(allocator: std.mem.Allocator, size: usize) !Reader {
        const buf = try allocator.alloc(u8, size);
        return .{
            .pos = 0,
            .start = 0,
            .buf = buf,
        };
    }

    pub fn deinit(self: *const Reader, allocator: std.mem.Allocator) void {
        allocator.free(self.buf);
    }

    pub fn readFrame(self: *Reader, socket: posix.socket_t) !Frame {
        while (true) {
            if (try self.bufferedFrame()) |frame| {
                return frame;
            }
            const pos = self.pos;
            const n = try posix.read(socket, self.buf[pos..]);
            if (n == 0) return error.Closed;
            self.pos += n;
        }
    }

    fn bufferedFrame(self: *Reader) !?Frame {
        const unprocessed = self.buf[self.start..self.pos];
        if (unprocessed.len < 2) return null;

        const fin = (unprocessed[0] & 0x80) != 0;
        const opcode = @as(u4, @truncate(unprocessed[0] & 0x0F));
        const mask = (unprocessed[1] & 0x80) != 0;
        const payload_len = @as(u7, @truncate(unprocessed[1] & 0x7F));

        var header_size: usize = 2;
        if (payload_len == 126) {
            header_size += 2;
        } else if (payload_len == 127) {
            header_size += 8;
        }
        if (mask) header_size += 4;

        if (unprocessed.len < header_size) return null;

        var final_payload_len: u64 = payload_len;
        var current_pos: usize = 2;
        if (payload_len == 126) {
            final_payload_len = std.mem.readInt(u16, unprocessed[2..4], .big);
            current_pos += 2;
        } else if (payload_len == 127) {
            final_payload_len = std.mem.readInt(u64, unprocessed[2..10], .big);
            current_pos += 8;
        }

        const total_size = header_size + final_payload_len;
        if (unprocessed.len < total_size) return null;

        var mask_key: ?[4]u8 = null;
        if (mask) {
            mask_key = unprocessed[current_pos..][0..4].*;
            current_pos += 4;
        }

        const payload = unprocessed[current_pos .. current_pos + final_payload_len];

        if (mask) {
            for (payload, 0..) |*byte, i| {
                byte.* ^= mask_key.?[i % 4];
            }
        }

        self.start += total_size;

        return Frame{
            .fin = fin,
            .opcode = opcode,
            .mask = mask,
            .payload_length = final_payload_len,
            .mask_key = mask_key,
            .payload = payload,
        };
    }

    fn ensureSpace(self: *Reader, space: usize) error{BufferTooSmall}!void {
        const buf = self.buf;
        if (buf.len < space) {
            return error.BufferTooSmall;
        }

        const start = self.start;
        const spare = buf.len - start;
        if (spare >= space) {
            return;
        }

        const unprocessed = buf[start..self.pos];
        std.mem.copyForwards(u8, buf[0..unprocessed.len], unprocessed);
        self.start = 0;
        self.pos = unprocessed.len;
    }
};
