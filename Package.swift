// swift-tools-version: 5.10

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
                "fastdds"
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .unsafeFlags(["-O", "-whole-module-optimization"], .when(configuration: .release)),
                .unsafeFlags(["-Onone"], .when(configuration: .debug))
            ]),
        .target(
            name: "fastdds"),
    ],
    cxxLanguageStandard: .cxx14
)
