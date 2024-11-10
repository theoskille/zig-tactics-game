pub fn toI32(value: anytype) i32 {
    return @as(i32, @intCast(value));
}
