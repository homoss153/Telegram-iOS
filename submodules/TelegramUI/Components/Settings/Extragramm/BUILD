load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "Extragramm",
    module_name = "Extragramm",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/Display",
        "//submodules/AsyncDisplayKit",
        "//submodules/TelegramCore",
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/TelegramPresentationData",
        "//submodules/AccountContext",
        "//submodules/ItemListUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
