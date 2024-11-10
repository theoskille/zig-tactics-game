const std = @import("std");
const net = std.net;
const posix = std.posix;

const Client = @import("client.zig").Client;
const MatchMaker = @import("matchMaker.zig").MatchMaker;
const MessageType = @import("protocol.zig").MessageType;

pub fn main() !void {
    std.debug.print("Starting server...\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var matchmaker = MatchMaker.init(allocator);
    defer matchmaker.deinit();

    const address = try std.net.Address.parseIp("127.0.0.1", 8080);

    const tpe: u32 = posix.SOCK.STREAM;
    const protocol = posix.IPPROTO.TCP;

    const listener = try posix.socket(address.any.family, tpe, protocol);
    defer posix.close(listener);

    try posix.setsockopt(listener, posix.SOL.SOCKET, posix.SO.REUSEADDR, &std.mem.toBytes(@as(c_int, 1)));
    try posix.bind(listener, &address.any, address.getOsSockLen());
    try posix.listen(listener, 128);

    std.debug.print("Listening on: {}\n", .{address});

    var pool: std.Thread.Pool = undefined;
    try std.Thread.Pool.init(&pool, .{ .allocator = allocator, .n_jobs = 64 });

    while (true) {
        var client_address: net.Address = undefined;
        var client_address_len: posix.socklen_t = @sizeOf(net.Address);

        const socket = posix.accept(listener, &client_address.any, &client_address_len, 0) catch |err| {
            std.debug.print("Error accepting connection: {}\n", .{err});
            continue;
        };

        const client = try Client.init(allocator, socket, client_address, &matchmaker);
        try pool.spawn(Client.handle, .{client});
    }
}
