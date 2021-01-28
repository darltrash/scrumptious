const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const stime = @import("sokol").time;
const sgapp = @import("sokol").app_gfx_glue;
const sfetch = @import("sokol").fetch;

const vec3 = @import("math.zig").Vec3;
const mat4 = @import("math.zig").Mat4;
const shd = @import("shaders/mainshader.zig");

pub const state = enum(u2) { game };
const gamestate = @import("game.zig");
pub var currentState: state = undefined;

const Vertex = packed struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    color: u32 = 0xFFFFFFFF,
    u: i16, v: i16
};

const _keystruct = struct {
    up:     bool = false,
    down:   bool = false,
    left:   bool = false,
    right:  bool = false,

    attack:  bool = false,

    up2:     bool = false,
    down2:   bool = false,
    left2:   bool = false,
    right2:  bool = false,

    attack2: bool = false,
    any:     bool = false
};
var key = _keystruct{};

var pass_action: sg.PassAction = .{};
var pip: sg.Pipeline = .{};
var bind: sg.Bindings = .{};
pub var screenWidth: f32 = 0;
pub var screenHeight: f32 = 0;

var delta: f32 = 0;

pub fn newTexture(data: *const [1024]u32, width: i32, height: i32) sg.Image {
    var img_desc: sg.ImageDesc = .{
        .width = width,
        .height = height,
    };
    img_desc.data.subimage[0][0] = sg.asRange(data);
    return sg.makeImage(img_desc);
}

pub fn setTexture(data: sg.Image) void {
    bind.fs_images[shd.SLOT_tex] = data;
}

export fn init() void {
    sg.setup(.{ .context = sgapp.context() });
    pass_action.colors[0] = .{
        .action = .CLEAR,
        .value = .{ // Eigengrau rocks, change my mind.
            .r = 0.086,
            .g = 0.086,
            .b = 0.113,
            .a = 1.0
        }
    };

    stime.setup();

    const N = 0x00000000;
    const Y = 0xFFFFFFFF;
    const P = 0xFFad03fc;
    const pixels1 = [32*32]u32 { // Much better :)   Still sorry :(
        P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,
        P,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,Y,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,Y,Y,Y,N,N,N,N,N,N,N,N,N,Y,Y,Y,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,Y,Y,Y,N,N,N,N,N,N,N,N,N,N,N,N,Y,Y,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,Y,Y,Y,N,N,N,Y,Y,N,N,N,N,Y,Y,N,N,Y,Y,N,N,N,N,N,N,N,N,P,
        P,N,N,N,Y,Y,Y,N,N,N,Y,N,Y,N,N,N,N,Y,Y,Y,N,N,Y,Y,N,N,N,N,N,N,N,P,
        P,N,N,N,Y,Y,N,N,N,N,Y,N,N,Y,N,N,Y,Y,N,N,Y,Y,Y,Y,N,N,N,N,Y,N,N,P,
        P,N,N,N,Y,Y,N,N,N,Y,N,N,N,Y,Y,N,Y,N,N,N,N,Y,N,Y,N,N,N,N,N,N,N,P,
        P,N,N,N,Y,Y,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,Y,Y,N,N,N,N,N,N,N,P,
        P,N,N,N,Y,Y,Y,N,N,N,N,N,Y,Y,N,N,N,N,Y,Y,N,N,Y,Y,N,N,N,N,N,N,N,P,
        P,N,N,N,Y,Y,Y,N,N,N,N,N,N,Y,Y,Y,Y,Y,Y,N,N,Y,Y,Y,N,N,N,N,N,N,N,P,
        P,N,N,N,N,Y,Y,Y,Y,N,N,N,N,N,N,N,N,N,N,N,Y,Y,Y,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,Y,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,Y,Y,N,N,N,N,N,Y,Y,N,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,Y,Y,N,N,N,N,N,Y,Y,N,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,Y,Y,N,N,N,N,N,Y,Y,Y,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,Y,Y,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,Y,Y,Y,Y,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,Y,Y,Y,Y,N,N,N,N,Y,Y,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,Y,Y,Y,N,N,N,N,N,N,Y,Y,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,Y,Y,Y,N,N,N,N,N,N,Y,Y,N,N,N,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,Y,Y,Y,Y,Y,Y,N,N,N,N,N,N,Y,Y,Y,Y,Y,N,N,N,N,N,N,N,N,P,
        P,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,N,P,
        P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P,P
    };

    setTexture(newTexture(&pixels1, 32, 32));

    // SETUP QUAD MESH (needed for all the sprites mumbo jumbo)
    const QuadVertices = [4]Vertex{
        .{ .x = 2, .y = 0, .u = 6553, .v = 6553},
        .{ .x = 2, .y = 2, .u = 6553, .v = 0},
        .{ .x = 0, .y = 2, .u = 0,    .v = 0},
        .{ .x = 0, .y = 0, .u = 0,    .v = 6553},
    };
    const QuadIndices = [6]u16{ 0, 1, 3, 1, 2, 3 };

    bind.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(QuadVertices) });
    bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(QuadIndices),
    });

    var pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.shaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .cull_mode = .FRONT,
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        }
    };
    pip_desc.colors[0].blend = .{
        .enabled = true,
        .src_factor_rgb = .SRC_ALPHA,
        .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
        .src_factor_alpha = .SRC_ALPHA,
        .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
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
    delta = @floatCast(f32, stime.sec(stime.diff(stime.now(), preframe)));
}

export fn cleanup() void {
    switch(currentState) {
        state.game => gamestate.cleanup()
    }
    sg.shutdown();
}

export fn input(ev: ?*const sapp.Event) void {
    const event = ev.?;
    if ((event.type == .KEY_DOWN) or (event.type == .KEY_UP)) {
        const key_pressed = event.type == .KEY_DOWN;
        key.any = key_pressed;
        switch (event.key_code) {
            .W => key.up = key_pressed,
            .S => key.down = key_pressed,
            .A => key.left = key_pressed,
            .D => key.right = key_pressed,

            .UP    => key.up2 = key_pressed,
            .DOWN  => key.down2 = key_pressed,
            .LEFT  => key.left2 = key_pressed,
            .RIGHT => key.right2 = key_pressed,
            else => {}
        }
    }
}

pub fn getKeys() *_keystruct {
    return &key;
}

pub fn main() void {
    setState(state.game);
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 1024,
        .height = 600,
        .window_title = "PROJECT SCRUMPTIOUS",
    });
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
