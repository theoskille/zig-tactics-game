const std = @import("std");
const posix = std.posix;

const Reader = @import("networkActions.zig").Reader;
const writeMessage = @import("networkActions.zig").writeMessage;
const MatchMaker = @import("matchMaker.zig").MatchMaker;
const Message = @import("protocol.zig").Message;
const Frame = @import("protocol.zig").Frame;
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
    websocketHandshakeCompleted: bool,
    allocator: std.mem.Allocator,

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
            .websocketHandshakeCompleted = false,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *const Client) void {
        self.reader.deinit(self.allocator);
        self.allocator.free(self.write_buf);
    }

    pub fn readWebsocketUpgradeRequest(self: *Client) !void {
        std.debug.print("reading websocket upgrade request from: {}\n", .{self.address});
        var buf: [1024]u8 = undefined;
        const bytes_read = try posix.read(self.socket, &buf);
        const request = buf[0..bytes_read];

        const is_websocket = std.mem.indexOf(u8, request, "Upgrade: websocket") != null;
        if (is_websocket) {
            std.debug.print("websocket upgrade detected\n", .{});

            // Find the Sec-WebSocket-Key
            const key_header = "Sec-WebSocket-Key: ";
            const key_start = std.mem.indexOf(u8, request, key_header) orelse return error.NoWebSocketKey;
            const key_end = std.mem.indexOf(u8, request[key_start..], "\r\n") orelse return error.InvalidHeader;
            const key = request[key_start + key_header.len .. key_start + key_end];

            // Generate accept key
            const magic_string = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
            var hasher = std.crypto.hash.Sha1.init(.{});
            hasher.update(key);
            hasher.update(magic_string);
            var hash: [20]u8 = undefined;
            hasher.final(&hash);

            // Base64 encode the hash
            var encoded: [28]u8 = undefined;
            _ = std.base64.standard.Encoder.encode(&encoded, &hash);

            // Send upgrade response
            const response = try std.fmt.allocPrint(self.allocator, "HTTP/1.1 101 Switching Protocols\r\n" ++
                "Upgrade: websocket\r\n" ++
                "Connection: Upgrade\r\n" ++
                "Sec-WebSocket-Accept: {s}\r\n" ++
                "\r\n", .{encoded[0..]});
            defer self.allocator.free(response);

            _ = try posix.write(self.socket, response);

            // Mark client as websocket
            self.websocketHandshakeCompleted = true;
        }
    }

    pub fn readFrame(self: *Client) !?Frame {
        return self.reader.readFrame(self.socket) catch |err| switch (err) {
            error.WouldBlock => return null,
            else => return err,
        };
    }

    pub fn writeFrame(self: *Client, payload: []const u8) !bool {
        if (self.to_write.len > 0) {
            return error.PendingMessage;
        }

        // Calculate frame header size
        var header_size: usize = 2; // Basic header is 2 bytes
        if (payload.len > 125) {
            if (payload.len > 65535) {
                header_size += 8; // 64-bit extended payload length
            } else {
                header_size += 2; // 16-bit extended payload length
            }
        }

        // Check if message fits in buffer
        if (header_size + payload.len > self.write_buf.len) {
            return error.MessageTooLarge;
        }

        // Construct frame header
        self.write_buf[0] = 0x82; // FIN=1, Opcode=2 (binary)

        // Set payload length
        if (payload.len <= 125) {
            self.write_buf[1] = @truncate(payload.len);
            header_size = 2;
        } else if (payload.len <= 65535) {
            self.write_buf[1] = 126;
            std.mem.writeInt(u16, self.write_buf[2..4], @truncate(payload.len), .big);
            header_size = 4;
        } else {
            self.write_buf[1] = 127;
            std.mem.writeInt(u64, self.write_buf[2..10], payload.len, .big);
            header_size = 10;
        }

        // Copy payload
        @memcpy(self.write_buf[header_size..][0..payload.len], payload);

        self.to_write = self.write_buf[0 .. header_size + payload.len];
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
