const std = @import("std");
const Client = @import("client.zig").Client;

pub const MatchMaker = struct {
    waiting_players: std.ArrayList(*Client),
    mutex: std.Thread.Mutex,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) MatchMaker {
        return MatchMaker{
            .waiting_players = std.ArrayList(*Client).init(allocator),
            .mutex = .{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *MatchMaker) void {
        self.waiting_players.deinit();
    }

    pub fn addPlayer(self: *MatchMaker, client: *Client) !?*Client {
        self.mutex.lock();
        defer self.mutex.unlock();

        // Check if there's a player waiting
        if (self.waiting_players.items.len > 0) {
            // Match found! Get the waiting player
            const opponent = self.waiting_players.orderedRemove(0);
            return opponent;
        }

        // No match found, add to waiting list
        try self.waiting_players.append(client);
        return null;
    }

    // Optional: Remove player if they cancel or disconnect
    pub fn removePlayer(self: *MatchMaker, client: *Client) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        for (self.waiting_players.items, 0..) |player, i| {
            if (player == client) {
                _ = self.waiting_players.orderedRemove(i);
                return;
            }
        }
    }
};
