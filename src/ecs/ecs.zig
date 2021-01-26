// ecs
pub const EntityTraitsType = @import("ecs/entity.zig").EntityTraitsType;

pub const Entity = @import("ecs/registry.zig").Entity;
pub const Registry = @import("ecs/registry.zig").Registry;
pub const BasicView = @import("ecs/views.zig").BasicView;
pub const BasicMultiView = @import("ecs/views.zig").BasicMultiView;
pub const BasicGroup = @import("ecs/groups.zig").BasicGroup;
pub const OwningGroup = @import("ecs/groups.zig").OwningGroup;
pub const ReverseSliceIterator = @import("ecs/utils.zig").ReverseSliceIterator;

// signals
pub const Signal = @import("signals/signal.zig").Signal;
pub const Dispatcher = @import("signals/dispatcher.zig").Dispatcher;
