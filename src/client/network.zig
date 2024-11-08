const std = @import("std");
const net = std.net;
const posix = std.posix;

pub const Client = struct {
    socket: posix.socket_t,

    pub fn init(address: []const u8, port: u16) !Client {
        const sock_addr = try std.net.Address.parseIp(address, port);
        const socket = try posix.socket(sock_addr.any.family, posix.SOCK.STREAM, posix.IPPROTO.TCP);
        errdefer posix.close(socket);

        try posix.connect(socket, &sock_addr.any, sock_addr.getOsSockLen());

        return Client{
            .socket = socket,
        };
    }

    pub fn deinit(self: *Client) void {
        posix.close(self.socket);
    }

    pub fn writeMessage(self: *Client, msg: []const u8) !void {
        var header: [4]u8 = undefined;
        std.mem.writeInt(u32, &header, @intCast(msg.len), .little);
        std.debug.print("length: {d}\n", .{msg.len});
        std.debug.print("header: {d}\n", .{header});
        std.debug.print("msg: {d}\n", .{msg});
        try writeAll(self.socket, &header);
        try writeAll(self.socket, msg);
    }

    pub fn readMessage(self: *Client, buf: []u8) ![]u8 {
        var header: [4]u8 = undefined;
        try readAll(self.socket, &header);

        const len = std.mem.readInt(u32, &header, .little);
        if (len > buf.len) {
            return error.BufferTooSmall;
        }

        const msg = buf[0..len];
        try readAll(self.socket, msg);
        return msg;
    }
};

fn writeAll(socket: posix.socket_t, msg: []const u8) !void {
    var pos: usize = 0;
    while (pos < msg.len) {
        const bytes_written = try posix.write(socket, msg[pos..]);
        if (bytes_written == 0) {
            return error.Closed;
        }
        pos += bytes_written;
    }
}

fn readAll(socket: posix.socket_t, buf: []u8) !void {
    var into = buf;
    while (into.len > 0) {
        const n = try posix.read(socket, into);
        if (n == 0) {
            return error.Closed;
        }
        into = into[n..];
    }
}
