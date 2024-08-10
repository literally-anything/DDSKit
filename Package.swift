// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DDSKit",
    products: [
        .library(
            name: "DDSKit",
            targets: ["DDSKit"]),
        .library(
            name: "fastdds",
            targets: ["fastdds"])
    ],
    targets: [
        .target(
            name: "DDSKit",
            dependencies: [
                "fastdds",
                "DDSKitInternal"
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .swiftLanguageMode(.v6),
                .unsafeFlags(["-O", "-whole-module-optimization"], .when(configuration: .release)),
                .unsafeFlags(["-Onone"], .when(configuration: .debug))
            ]),
        .target(
            name: "fastdds",
            dependencies: [
                "DDSKitInternal"
            ],
            cxxSettings: [
                .headerSearchPath("../../.compatibility-headers/")
            ]),
        .target(
            name: "DDSKitInternal",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .swiftLanguageMode(.v6),
                .unsafeFlags([
                    "-O",
                    "-emit-clang-header-path", ".compatibility-headers/DDSKitInternal-Swift.h"
                ])
            ]),
    ],
    cxxLanguageStandard: .cxx14
)
