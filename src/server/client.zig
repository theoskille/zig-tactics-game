const std = @import("std");
const posix = std.posix;

const Reader = @import("networkActions.zig").Reader;
const writeMessage = @import("networkActions.zig").writeMessage;
const MatchMaker = @import("matchMaker.zig").MatchMaker;
const Message = @import("protocol.zig").Message;
const GameFoundPayload = @import("protocol.zig").GameFoundPayload;
const ClientList = std.DoublyLinkedList(*Client);
const ClientNode = ClientList.Node;

pub const Client = struct {
    socket: posix.socket_t,
    address: std.net.Address,
    reader: Reader,
    to_write: []u8,
    write_buf: []u8,
    read_timeout: i64,
    read_timeout_node: *ClientNode,

    pub fn init(allocator: std.mem.Allocator, socket: posix.socket_t, address: std.net.Address) !Client {
        const reader = try Reader.init(allocator, 4096);
        errdefer reader.deinit(allocator);

        const write_buf = try allocator.alloc(u8, 4096);
        errdefer allocator.free(write_buf);

        return .{
            .reader = reader,
            .socket = socket,
            .address = address,
            .to_write = &.{},
            .write_buf = write_buf,
            .read_timeout = 0, // let the server set this
            .read_timeout_node = undefined, // hack/ugly, let the server set this when init returns
        };
    }

    pub fn deinit(self: *const Client, allocator: std.mem.Allocator) void {
        self.reader.deinit(allocator);
        allocator.free(self.write_buf);
    }

    pub fn readMessage(self: *Client) !?Message {
        return self.reader.readMessage(self.socket) catch |err| switch (err) {
            error.WouldBlock => return null,
            else => return err,
        };
    }

    pub fn writeMessage(self: *Client, msg: Message) !bool {
        if (self.to_write.len > 0) {
            return error.PendingMessage;
        }

        if (msg.payload.len + 6 > self.write_buf.len) {
            return error.MessageTooLarge;
        }

        std.mem.writeInt(u32, self.write_buf[0..4], @intCast(msg.payload.len), .little);
        std.mem.writeInt(u16, self.write_buf[4..6], @intFromEnum(msg.type), .little);
        const end = msg.payload.len + 6;
        @memcpy(self.write_buf[6..end], msg.payload);

        self.to_write = self.write_buf[0..end];
        return self.write();
    }

    pub fn write(self: *Client) !bool {
        var buf = self.to_write;
        defer self.to_write = buf;
        while (buf.len > 0) {
            const n = posix.write(self.socket, buf) catch |err| switch (err) {
                error.WouldBlock => return false,
                else => return err,
            };

            if (n == 0) {
                return error.Closed;
            }
            buf = buf[n..];
        } else {
            return true;
        }
    }
};
