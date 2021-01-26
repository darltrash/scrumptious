const std = @import("std");
const ecs = @import("ecs");
const sokol = @import("sokol");
const main = @import("main.zig");

pub const _GRAVITY = struct { x: f64, y: f64 };
pub const Position = struct { x: f64, y: f64 };
pub const Velocity = struct { x: f64, y: f64 };

pub fn processVelocity(reg: *ecs.Registry, delta: f64) void {
    var view = reg.view(.{ Position, Velocity }, .{});
    var iter = view.iterator();

    while (iter.next()) |entity| {
        var pos = view.get(Position, entity);
        var vel = view.get(Velocity, entity);

        pos.*.x += vel.x * delta;
        pos.*.y += vel.y * delta;
    }
}

pub const Mass = struct {
    enable: bool = true,
    amount: f64 = 0
};

pub fn processGravity(reg: *ecs.Registry, gravity: _GRAVITY, delta: f64) void {
    var view = reg.view(.{ Mass, Velocity }, .{});
    var iter = view.iterator();

    while (iter.next()) |entity| {
        var mas = view.get(Mass,     entity);
        var vel = view.get(Velocity, entity);

        vel.*.x += mas.amount * gravity.x;
        vel.*.y += mas.amount * gravity.y;
    }
}

pub const Drawable = struct {
    ox: f64, oy: f64,
    w: f64, h: f64,
    sx: f64 = 1, sy: f64 = 1
};

pub fn processDrawables(reg: *ecs.Registry, delta: f64) void {
    var view = reg.view(.{ Position, Velocity }, .{});
    var iter = view.iterator();

    while (iter.next()) |entity| {
        var pos = view.get(Position, entity);
        var vel = view.get(Velocity, entity);

        main.rectangle(40, 80, 30, 30);
        main.rectangle(0, 0, 30, 30);
    }
}

// Name     Static     Collides with
// -------- ---------- -------------------
// World    True       Nothing
// Enemy    False      Player, World
// Player   False      World
pub const AABBKinds = enum { world, enemy, player };
pub const AABB = struct {
    enabled: bool = true,
    kind: AABBKinds = AABBKinds.world,
    w: f64, h: f64, ox: f64 = 0, oy: f64 = 0,

    pub fn collidingWith(a: *AABB, apos: Position, b: AABB, bpos: Position) bool {
        return (apos.x < bpos.x+b.w) &
               (bpos.x < apos.x+a.w) &
               (apos.y < bpos.y+b.h) &
               (bpos.y < apos.y+a.h);
    }
};

pub const PlayerStates = enum { normal, falling, dizzy };
pub const PlayerCharacter = enum { goathim, humanher };
pub const Player = struct {
    enableMovement: bool = true,
    currentState: PlayerStates = PlayerStates.normal,
    character: PlayerCharacter = PlayerCharacter.goathim
};

pub const Tile = struct {
    static: bool = true
};
