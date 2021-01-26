const std = @import("std");
const ecs = @import("ecs");
const sokol = @import("sokol");
const main = @import("main.zig");

pub const _GRAVITY = struct { x: f32, y: f32 };
pub const Position = struct { x: f32, y: f32 };
pub const Velocity = struct { x: f32, y: f32 };

pub fn processVelocity(reg: *ecs.Registry, delta: f32) void {
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
    amount: f32 = 0
};

pub fn processGravity(reg: *ecs.Registry, gravity: _GRAVITY, delta: f32) void {
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
    ox: f32, oy: f32,
    w: f32, h: f32,
    sx: f32 = 1, sy: f32 = 1
};


// Name     Static     Collides with
// -------- ---------- -------------------
// World    True       Nothing
// Enemy    False      Player, World
// Player   False      World
pub const AABBKinds = enum { world, enemy, player };
pub const AABB = struct {
    enabled: bool = true,
    kind: AABBKinds = AABBKinds.world,
    w: f32, h: f32, ox: f32 = 0, oy: f32 = 0,

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
    character: PlayerCharacter = PlayerCharacter.goathim,
    velocity: f32 = 200
};

pub fn processPlayer(reg: *ecs.Registry, delta: f32) void {
    var view = reg.view(.{ Velocity, Player }, .{});
    var iter = view.iterator();

    while (iter.next()) |entity| {
        var vel = view.get(Velocity, entity);
        var player = view.get(Player, entity);
        var keypress = main.getKeys();

        vel.*.x = 0;
        vel.*.y = 0;

        if (keypress.up) {
            vel.*.y -= player.velocity;
        }
        if (keypress.down) {
            vel.*.y += player.velocity;
        }

        if (keypress.left) {
            vel.*.x -= player.velocity;
        }
        if (keypress.right) {
            vel.*.x += player.velocity;
        }
    }
}

pub fn drawPlayer(reg: *ecs.Registry, delta: f32) void {
    var view = reg.view(.{ Position, Player }, .{});
    var iter = view.iterator();

    while (iter.next()) |entity| {
        var pos = view.get(Position, entity);
        var vel = view.get(Velocity, entity);

        main.rectangle(pos.x, pos.y, 30, 30);
    }
}

pub const Tile = struct {
    static: bool = true
};
