const std = @import("std");
const ecs = @import("ecs");
const defs = @import("definition.zig");
const sokol = @import("sokol");

var gravity = defs._GRAVITY{ .x = 0, .y = 5 };
var ecsreg: ecs.Registry = undefined;

pub fn init() void {
    ecsreg = ecs.Registry.init(std.heap.c_allocator);

    var ent = ecsreg.create();
    ecsreg.add(ent, defs.Position{.x = 0, .y = 20});
    ecsreg.add(ent, defs.Velocity{.x = 0, .y = 0});
    ecsreg.add(ent, defs.Player{});

    var ent2 = ecsreg.create();
    ecsreg.add(ent2, defs.Position{.x = 0, .y = 60});
    ecsreg.add(ent2, defs.Velocity{.x = 0, .y = 0});
    ecsreg.add(ent2, defs.Player{
        .character = defs.PlayerCharacter.sis
    });
}

pub fn process(delta: f32) void {
    defs.processGravity(&ecsreg, gravity, delta);
    defs.processPlayer(&ecsreg, delta);
    defs.processVelocity(&ecsreg, delta);
}

pub fn draw(delta: f32) void {
    defs.drawPlayer(&ecsreg, delta);
}
pub fn cleanup() void { ecsreg.deinit(); }
