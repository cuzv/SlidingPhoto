load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SlidingPhoto",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    data = [
        ":SlidingPhotoResources",
    ],
    module_name = "SlidingPhoto",
    visibility = [
        "//visibility:public",
    ],
)

apple_resource_bundle(
    name = "SlidingPhotoResources",
    bundle_name = "SlidingPhoto",
    resources = glob([
        "Resources/*",
    ]),
)
