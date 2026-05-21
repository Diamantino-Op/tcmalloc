# platforms/cc_config.bzl
load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "tool_path", "feature", "flag_set", "flag_group")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

all_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
]

# Group all actions that execute a dynamic binary or archive linking step
all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

def _impl(ctx):
    sysroot_path = ctx.var.get("HORIZON_SYSROOT", "sysroot")
    toolchain_path = ctx.var.get("HORIZON_TOOLCHAIN", "toolchain")

    default_flags_feature = feature(
        name = "horizonos_default_flags",
        enabled = True,
        flag_sets = [
            # 1. Apply standard C++ compilation flags
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-stdlib=libc++"],
                    ),
                ],
            ),
            # 2. Apply explicit target linker flags
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "--rtlib=compiler-rt",
                            "-stdlib=libc++",
                            "--unwindlib=libunwind",
                            "-lc++abi",
                        ],
                    ),
                ],
            ),
        ],
    )
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "horizonos-compiler",
        host_system_name = "x86_64-unknown-linux-gnu",
        target_system_name = "x86_64-horizonos-elf",
        target_cpu = "x86_64",
        target_libc = "unknown",
        compiler = "clang",
        cxx_builtin_include_directories = [
            toolchain_path,
            sysroot_path,
        ],
        features = [default_flags_feature],
        tool_paths = [
            tool_path(name = "gcc", path = toolchain_path + "/bin/clang"),
            tool_path(name = "cpp", path = toolchain_path + "/bin/clang++"),
            tool_path(name = "ar", path = toolchain_path + "/bin/llvm-ar"),
            tool_path(name = "nm", path = toolchain_path + "/bin/llvm-nm"),
            tool_path(name = "ld", path = toolchain_path + "/bin/ld.lld"),
            tool_path(name = "strip", path = toolchain_path + "/bin/llvm-strip"),
            tool_path(name = "objdump", path = toolchain_path + "/bin/llvm-objdump"),
            tool_path(name = "objcopy", path = toolchain_path + "/bin/llvm-objcopy"),
            tool_path(name = "as", path = toolchain_path + "/bin/clang"),
            tool_path(name = "gcov", path = "/usr/bin/gcov"),
        ],
    )

horizonos_cc_config = rule(
    implementation = _impl,
    provides = [CcToolchainConfigInfo],
)