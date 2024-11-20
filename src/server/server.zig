const std = @import("std");
const net = std.net;
const posix = std.posix;
const Client = @import("client.zig").Client;

const log = std.log.scoped(.tcp_demo);

const READ_TIMEOUT_MS = 60_000; //1 MINUTE

const ClientList = std.DoublyLinkedList(*Client);
const ClientNode = ClientList.Node;

pub const Server = struct {
    allocator: std.mem.Allocator,
    connected: usize,
    polls: []posix.pollfd,
    client_pool: std.heap.MemoryPool(Client),
    clients: []*Client,
    client_polls: []posix.pollfd,
    read_timeout_list: ClientList,
    client_node_pool: std.heap.MemoryPool(ClientNode),

    pub fn init(allocator: std.mem.Allocator, max: usize) !Server {
        const polls = try allocator.alloc(posix.pollfd, max + 1);
        errdefer allocator.free(polls);

        const clients = try allocator.alloc(*Client, max);
        errdefer allocator.free(clients);

        return .{
            .polls = polls,
            .clients = clients,
            .client_polls = polls[1..],
            .connected = 0,
            .allocator = allocator,
            .client_pool = std.heap.MemoryPool(Client).init(allocator),
            .read_timeout_list = .{},
            .client_node_pool = std.heap.MemoryPool(ClientNode).init(allocator),
        };
    }

    pub fn deinit(self: *Server) void {
        self.allocator.free(self.polls);
        self.allocator.free(self.clients);
        self.client_pool.deinit();
        self.client_node_pool.deinit();
    }

    pub fn run(self: *Server, address: std.net.Address) !void {
        const tpe: u32 = posix.SOCK.STREAM | posix.SOCK.NONBLOCK;
        const protocol = posix.IPPROTO.TCP;
        const listener = try posix.socket(address.any.family, tpe, protocol);
        defer posix.close(listener);

        try posix.setsockopt(listener, posix.SOL.SOCKET, posix.SO.REUSEADDR, &std.mem.toBytes(@as(c_int, 1)));
        try posix.bind(listener, &address.any, address.getOsSockLen());
        try posix.listen(listener, 128);

        std.debug.print("Listening at: {}\n", .{address});

        self.polls[0] = .{
            .fd = listener,
            .revents = 0,
            .events = posix.POLL.IN,
        };

        var read_timeout_list = &self.read_timeout_list;

        while (true) {
            const next_timeout = self.enforceTimeout();
            std.debug.print("polling...\n", .{});
            _ = try posix.poll(self.polls[0 .. self.connected + 1], next_timeout);
            if (self.polls[0].revents != 0) {
                self.accept(listener) catch |err| log.err("failed to accept: {}", .{err});
            }

            var i: usize = 0;
            while (i < self.connected) {
                // std.debug.print("i: {}\n", .{i});
                // std.debug.print("connected: {}\n", .{self.connected});
                const revents = self.client_polls[i].revents;
                if (revents == 0) {
                    //not ready, skip
                    i += 1;
                    continue;
                }

                var client = self.clients[i];
                if (revents & posix.POLL.IN == posix.POLL.IN) {
                    std.debug.print("reading from: {}\n", .{client.address});
                    if (client.websocketHandshakeCompleted) {
                        //socket ready to read
                        while (true) {
                            const frame = client.readFrame() catch {
                                std.debug.print("error reading message\n", .{});
                                self.removeClient(i);
                                break;
                            } orelse {
                                i += 1;
                                break;
                            };
                            std.debug.print("Frame received: {}\n", .{frame});
                            std.debug.print("Frame payload: {s}\n", .{frame.payload});

                            client.read_timeout = std.time.milliTimestamp() + READ_TIMEOUT_MS;
                            read_timeout_list.remove(client.read_timeout_node);
                            read_timeout_list.append(client.read_timeout_node);

                            const written = client.writeFrame(frame.payload) catch {
                                self.removeClient(i);
                                break;
                            };
                            if (written == false) {
                                self.client_polls[i].events = posix.POLL.OUT;
                                break;
                            }
                        }
                    } else {
                        try client.readWebsocketUpgradeRequest();
                        i += 1;
                    }
                } else if (revents & posix.POLL.OUT == posix.POLL.OUT) {
                    //socket ready to write
                    const written = client.write() catch {
                        self.removeClient(i);
                        continue;
                    };
                    if (written) {
                        self.client_polls[i].events = posix.POLL.IN;
                    }
                }
            }
        }
    }

    pub fn enforceTimeout(self: *Server) i32 {
        const now = std.time.milliTimestamp();

        var node = self.read_timeout_list.first;
        while (node) |n| {
            const client = n.data;
            const diff = client.read_timeout - now;
            if (diff > 0) {
                return @intCast(diff);
            }
            posix.shutdown(client.socket, .recv) catch {};
            node = n.next;
        } else {
            return -1;
        }
    }

    fn accept(self: *Server, listener: posix.socket_t) !void {
        const space = self.client_polls.len - self.connected;
        for (0..space) |_| {
            var address: net.Address = undefined;
            var address_len: posix.socklen_t = @sizeOf(net.Address);
            const socket = posix.accept(listener, &address.any, &address_len, posix.SOCK.NONBLOCK) catch |err| switch (err) {
                error.WouldBlock => return,
                else => return err,
            };

            std.debug.print("accepted connection from: {}\n", .{address});

            const client = try self.client_pool.create();
            errdefer self.client_pool.destroy(client);
            client.* = Client.init(self.allocator, socket, address) catch |err| {
                posix.close(socket);
                log.err("failed to initialize client: {}", .{err});
                return;
            };

            client.read_timeout = std.time.milliTimestamp() + READ_TIMEOUT_MS;
            client.read_timeout_node = try self.client_node_pool.create();
            errdefer self.client_node_pool.destroy(client.read_timeout_node);

            client.read_timeout_node.* = .{
                .next = null,
                .prev = null,
                .data = client,
            };
            self.read_timeout_list.append(client.read_timeout_node);

            const connected = self.connected;
            self.clients[connected] = client;
            self.client_polls[connected] = .{
                .fd = socket,
                .revents = 0,
                .events = posix.POLL.IN,
            };
            self.connected = connected + 1;
        } else {
            self.polls[0].events = 0;
        }
    }

    fn removeClient(self: *Server, at: usize) void {
        std.debug.print("removed client\n", .{});
        var client = self.clients[at];
        defer {
            posix.close(client.socket);
            self.client_node_pool.destroy(client.read_timeout_node);
            client.deinit();
            self.client_pool.destroy(client);
        }

        const last_index = self.connected - 1;
        self.clients[at] = self.clients[last_index];
        self.client_polls[at] = self.client_polls[last_index];
        self.connected = last_index;

        // Maybe the listener was disabled because we were full,
        // but now we have a free slot.
        self.polls[0].events = posix.POLL.IN;

        self.read_timeout_list.remove(client.read_timeout_node);
    }
};
