load("@build_bazel_rules_ios//rules:framework.bzl", "apple_framework")

apple_framework(
    name = "SlidingPhoto",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    platforms = {
        "ios": "9.0",
    },
    swift_version = "5.9",
    visibility = [
        "//visibility:public",
    ],
)
