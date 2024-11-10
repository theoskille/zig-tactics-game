const std = @import("std");
const posix = std.posix;
const Message = @import("protocol.zig").Message;

pub const Reader = struct {
    buf: []u8,
    pos: usize = 0,
    start: usize = 0,
    socket: posix.socket_t,

    pub fn readMessage(self: *Reader) !Message {
        while (true) {
            if (try self.bufferedMessage()) |msg| {
                return msg;
            }
            const pos = self.pos;
            const n = try posix.read(self.socket, self.buf[pos..]);
            if (n == 0) {
                return error.Closed;
            }
            self.pos = pos + n;
        }
    }

    fn bufferedMessage(self: *Reader) !?Message {
        const buf = self.buf;
        const pos = self.pos;
        const start = self.start;

        std.debug.assert(pos >= start);
        const unprocessed = buf[start..pos];

        // Need at least length (4 bytes) + message type (2 bytes)
        if (unprocessed.len < 6) {
            self.ensureSpace(6 - unprocessed.len) catch unreachable;
            return null;
        }

        // Read total message length (includes type + payload)
        const message_len = std.mem.readInt(u32, unprocessed[0..4], .little);

        // the total length we need is length prefix (4) + message contents (message_len)
        const total_len = message_len + 4;

        if (unprocessed.len < total_len) {
            try self.ensureSpace(total_len);
            return null;
        }

        // Read the message type (2 bytes)
        const type_int = std.mem.readInt(u16, unprocessed[4..6], .little);

        // Create the message
        const message = Message{
            .type = @enumFromInt(type_int),
            // Payload is everything after the type
            .payload = unprocessed[6..total_len],
        };

        self.start += total_len;
        return message;
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
