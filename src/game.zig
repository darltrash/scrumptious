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
    ecsreg.add(ent, defs.Velocity{.x = 30, .y = 0});
    ecsreg.add(ent, defs.Mass{.amount = 2});
}

pub fn process(delta: f64) void {
    defs.processGravity(&ecsreg, gravity, delta);
    defs.processVelocity(&ecsreg, delta);
}

pub fn draw(delta: f64) void {
    defs.processDrawables(&ecsreg, delta);
}
pub fn cleanup() void { ecsreg.deinit(); }
