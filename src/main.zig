const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const stime = @import("sokol").time;
const sgapp = @import("sokol").app_gfx_glue;

const vec3  = @import("math.zig").Vec3;
const mat4  = @import("math.zig").Mat4;
const shd = @import("shaders/mainshader.zig");

pub const state = enum(u2) { game };
const gamestate = @import("game.zig");
pub var currentState: state = undefined;

const Vertex = packed struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    color: u32 = 0xA600FF,
    u: i16, v: i16
};

var pass_action: sg.PassAction = .{};
var pip: sg.Pipeline = .{};
var bind: sg.Bindings = .{};
pub var screenWidth: f32 = 0;
pub var screenHeight: f32 = 0;

var delta: f64 = 0;

export fn init() void {
    sg.setup(.{ .context = sgapp.context() });
    pass_action.colors[0] = .{
        .action = .CLEAR,
        .val = .{ 0.086, 0.086, 0.113, 1.0 } // Eigengrau rocks, change my mind.
    };

    stime.setup();

    const pixels = [4*4]u32 {
        0xFFF0FFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
        0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
        0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
        0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
    };
    var img_desc: sg.ImageDesc = .{
        .width = 4,
        .height = 4,
    };
    img_desc.data.subimage[0][0] = sg.asRange(pixels);
    bind.fs_images[shd.SLOT_tex] = sg.makeImage(img_desc);

    // SETUP QUAD MESH (needed for all the sprites mumbo jumbo)
    const QuadVertices = [_]Vertex{
        .{ .x = 2, .y = 2, .u = 1, .v = 1},
        .{ .x = 2, .y = 0, .u = 1, .v = 0},
        .{ .x = 0, .y = 0, .u = 0, .v = 0},
        .{ .x = 0, .y = 2, .u = 0, .v = 1},
    };
    const QuadIndices = [_]u16{ 0, 1, 3, 1, 2, 3 };

    bind.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(QuadVertices) });
    bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(QuadIndices),
    });

    var pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.shaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
    };

    pip_desc.layout.attrs[shd.ATTR_vs_pos].format = .FLOAT3;
    pip_desc.layout.attrs[shd.ATTR_vs_color0].format = .UBYTE4N;
    pip_desc.layout.attrs[shd.ATTR_vs_texcoord0].format = .SHORT2N;
    pip = sg.makePipeline(pip_desc);
}

pub fn rectangle(x: f32, y: f32, w: f32, h: f32) void {
    // Sorry for the poopcode in here :(
    const scale = mat4.scale(w/screenWidth, h/screenHeight, 1);
    const trans = mat4.translate(.{
        .x = x / screenWidth,
        .y = y / -screenHeight,
        .z = 0
    });

    sg.applyUniforms(.VS, shd.SLOT_vs_params, sg.asRange(shd.VsParams {
        .mvp = mat4.mul(trans, scale)
    }));

    sg.draw(0, 6, 1);
}

export fn frame() void {
    screenWidth  = sapp.widthf();
    screenHeight = sapp.heightf();

    var preframe = stime.now();
        switch(currentState) {
            state.game => gamestate.process(delta)
        }

        sg.beginDefaultPass(pass_action, sapp.width(), sapp.height());
        sg.applyPipeline(pip);
        sg.applyBindings(bind);
            switch(currentState) {
                state.game => gamestate.draw(delta)
            }
        sg.endPass();
        sg.commit();
    delta = stime.sec(stime.diff(stime.now(), preframe));
}

export fn cleanup() void {
    switch(currentState) {
        state.game => gamestate.cleanup()
    }
    sg.shutdown();
}

pub fn setState(newState: state) void {
    switch(currentState) {
        state.game => gamestate.cleanup()
    }
    switch(currentState) {
        state.game => gamestate.init()
    }
    currentState = newState;
}

pub fn main() void {
    setState(state.game);
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 1024,
        .height = 600,
        .window_title = "PROJECT SCRUMPTIOUS",
    });
}
