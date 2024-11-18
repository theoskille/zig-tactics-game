const std = @import("std");
const net = std.net;
const posix = std.posix;

const Client = @import("client.zig").Client;
const MatchMaker = @import("matchMaker.zig").MatchMaker;
const MessageType = @import("protocol.zig").MessageType;
const Server = @import("server.zig").Server;

const log = std.log.scoped(.tcp_demo);

pub fn main() !void {
    std.debug.print("Starting server...\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var matchmaker = MatchMaker.init(allocator);
    defer matchmaker.deinit();

    var server = try Server.init(allocator, 4096);
    defer server.deinit();

    const address = try std.net.Address.parseIp("0.0.0.0", 8080);
    try server.run(address);

    std.debug.print("STOPPED\n", .{});
}
