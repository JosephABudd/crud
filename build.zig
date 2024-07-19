const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dvui_dep = b.dependency(
        "dvui",
        .{ .target = target, .optimize = optimize },
    );
    const sqlite_dep = b.dependency(
        "fridge",
        .{
            .bundle = true,
        },
    );

    // Framework modules.

    // channel_mod. A framework deps/ module.
    const channel_mod = b.addModule(
        "channel",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/channel/api.zig",
                },
            },
        },
    );

    // closedownjobs_mod. A framework deps/ module.
    const closedownjobs_mod = b.addModule(
        "closedownjobs",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/closedownjobs/api.zig",
                },
            },
        },
    );

    // closer_mod. A framework deps/ module.
    const closer_mod = b.addModule(
        "closer",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/closer/api.zig",
                },
            },
        },
    );

    // counter_mod. A framework deps/ module.
    const counter_mod = b.addModule(
        "counter",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/counter/api.zig",
                },
            },
        },
    );

    // framers_mod. A framework deps/ module.
    const framers_mod = b.addModule(
        "framers",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/framers/api.zig",
                },
            },
        },
    );

    // lock_mod. A framework deps/ module.
    const lock_mod = b.addModule(
        "lock",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/lock/api.zig",
                },
            },
        },
    );

    // message_mod. A framework deps/ module.
    const message_mod = b.addModule(
        "message",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/message/api.zig",
                },
            },
        },
    );

    // modal_params_mod. A framework deps/ module.
    const modal_params_mod = b.addModule(
        "modal_params",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/modal_params/api.zig",
                },
            },
        },
    );

    // screen_pointers_mod. A framework frontend/ module.
    const screen_pointers_mod = b.addModule(
        "screen_pointers",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/frontend/screen_pointers.zig",
                },
            },
        },
    );

    // startup_mod. A framework deps/ module.
    const startup_mod = b.addModule(
        "startup",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/startup/api.zig",
                },
            },
        },
    );

    // various_mod. A framework deps/ module.
    const various_mod = b.addModule(
        "various",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/various/api.zig",
                },
            },
        },
    );

    // widget_mod. A framework deps/ module.
    const widget_mod = b.addModule(
        "widget",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/widget/api.zig",
                },
            },
        },
    );

    // My modules.

    // my deps/store/ module.
    const store_mod = b.addModule(
        "store",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/store/api.zig",
                },
            },
        },
    );

    // my deps/record/ module.
    const record_mod = b.addModule(
        "record",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/deps/record/api.zig",
                },
            },
        },
    );

    // Framework module dependencies.

    // Dependencies for channel_mod. A framework deps/ module.
    channel_mod.addImport("message", message_mod);
    channel_mod.addImport("various", various_mod);

    // Dependencies for closedownjobs_mod. A framework deps/ module.
    closedownjobs_mod.addImport("counter", counter_mod);

    // Dependencies for closer_mod. A framework deps/ module.
    closer_mod.addImport("closedownjobs", closedownjobs_mod);
    closer_mod.addImport("dvui", dvui_dep.module("dvui"));
    closer_mod.addImport("framers", framers_mod);
    closer_mod.addImport("lock", lock_mod);
    closer_mod.addImport("modal_params", modal_params_mod);
    closer_mod.addImport("various", various_mod);

    // Dependencies for framers_mod. A framework deps/ module.
    framers_mod.addImport("startup", startup_mod);
    framers_mod.addImport("dvui", dvui_dep.module("dvui"));
    framers_mod.addImport("modal_params", modal_params_mod);
    framers_mod.addImport("various", various_mod);
    framers_mod.addImport("lock", lock_mod);

    // Dependencies for message_mod. A framework deps/ module.
    message_mod.addImport("counter", counter_mod);
    message_mod.addImport("closedownjobs", closedownjobs_mod);
    message_mod.addImport("framers", framers_mod);
    message_mod.addImport("record", record_mod);
    message_mod.addImport("various", various_mod);

    // Dependencies for modal_params_mod. A framework deps/ module.
    modal_params_mod.addImport("closedownjobs", closedownjobs_mod);

    // Dependencies for screen_pointers_mod. A framework frontend/ module.
    screen_pointers_mod.addImport("channel", channel_mod);
    screen_pointers_mod.addImport("closedownjobs", closedownjobs_mod);
    screen_pointers_mod.addImport("closer", closer_mod);
    screen_pointers_mod.addImport("dvui", dvui_dep.module("dvui"));
    screen_pointers_mod.addImport("framers", framers_mod);
    screen_pointers_mod.addImport("lock", lock_mod);
    screen_pointers_mod.addImport("message", message_mod);
    screen_pointers_mod.addImport("modal_params", modal_params_mod);
    screen_pointers_mod.addImport("record", record_mod);
    screen_pointers_mod.addImport("screen_pointers", screen_pointers_mod);
    screen_pointers_mod.addImport("startup", startup_mod);
    screen_pointers_mod.addImport("various", various_mod);
    screen_pointers_mod.addImport("widget", widget_mod);

    // Dependencies for startup_mod. A framework deps/ module.
    startup_mod.addImport("channel", channel_mod);
    startup_mod.addImport("closedownjobs", closedownjobs_mod);
    startup_mod.addImport("dvui", dvui_dep.module("dvui"));
    startup_mod.addImport("framers", framers_mod);
    startup_mod.addImport("modal_params", modal_params_mod);
    startup_mod.addImport("various", various_mod);
    startup_mod.addImport("screen_pointers", screen_pointers_mod);
    startup_mod.addImport("store", store_mod);

    // Dependencies for widget_mod. A framework deps/ module.
    widget_mod.addImport("dvui", dvui_dep.module("dvui"));
    widget_mod.addImport("lock", lock_mod);
    widget_mod.addImport("framers", framers_mod);
    widget_mod.addImport("startup", startup_mod);
    widget_mod.addImport("various", various_mod);

    // MY MODULES DEPENDENCIES.

    // Dependencies for record_mod. My deps/ module.
    record_mod.addImport("counter", counter_mod);

    // Dependencies for store_mod. My deps/ module.
    store_mod.addImport("record", record_mod);
    store_mod.addImport("sqlite", sqlite_dep.module("fridge"));

    const exe = b.addExecutable(.{
        .name = "crud",
        .root_source_file = .{
            .src_path = .{
                .owner = b,
                .sub_path = "src/main.zig",
            },
        },
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("dvui", dvui_dep.module("dvui"));
    exe.root_module.addImport("SDLBackend", dvui_dep.module("SDLBackend"));

    // Framework modules.
    exe.root_module.addImport("channel", channel_mod);
    exe.root_module.addImport("closedownjobs", closedownjobs_mod);
    exe.root_module.addImport("closer", closer_mod);
    exe.root_module.addImport("counter", counter_mod);
    exe.root_module.addImport("framers", framers_mod);
    exe.root_module.addImport("lock", lock_mod);
    exe.root_module.addImport("message", message_mod);
    exe.root_module.addImport("modal_params", modal_params_mod);
    exe.root_module.addImport("screen_pointers", screen_pointers_mod);
    exe.root_module.addImport("startup", startup_mod);
    exe.root_module.addImport("various", various_mod);
    exe.root_module.addImport("widget", widget_mod);

    // my deps modules.
    exe.root_module.addImport("record", record_mod);
    exe.root_module.addImport("store", store_mod);

    // vendor/fridge/ module.
    exe.root_module.addImport("sqlite", sqlite_dep.module("fridge"));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const sep_test = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_sep_unit_tests = b.addRunArtifact(sep_test);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_sep_unit_tests.step);
}
