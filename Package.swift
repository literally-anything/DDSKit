/**
 * Package.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 8/19/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport
import FoundationEssentials

var cSettings: [CSetting] = []
var cxxSettings: [CXXSetting] = []

#if !os(macOS)
let swift_cxx_flags_path = "./swift_cxx_flags"
if FileManager.default.fileExists(atPath: swift_cxx_flags_path) {
    let flags = try? String(contentsOfFile: swift_cxx_flags_path, encoding: .utf8).split(whereSeparator: \.isNewline)
    if let flags {
        let stringFlags = flags.map { String($0) }
        cSettings.append(.unsafeFlags(stringFlags))
        cxxSettings.append(.unsafeFlags(stringFlags))
    }
}
#endif

let swiftSettings: [SwiftSetting] = [
    .interoperabilityMode(.Cxx),
    .enableUpcomingFeature("InternalImportsByDefault")
]

let package = Package(
    name: "DDSKit",
    products: [
        .library(
            name: "DDSKit",
            targets: ["DDSKit"]
        )
    ],
    dependencies: [
        // .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "DDSKit",
            dependencies: [
                // "DDSKitMacros",
                "_CFastDDS",
                .product(name: "Logging", package: "swift-log")
            ],
            cSettings: cSettings,
            cxxSettings: cxxSettings,
            swiftSettings: swiftSettings
        ),
        .target(
            name: "_CFastDDS",
            dependencies: [
                "_FastDDSHelpers"
            ],
            cSettings: cSettings,
            cxxSettings: cxxSettings + [
                .headerSearchPath("../../.compatibility-headers/")
            ],
            linkerSettings: [
                .linkedLibrary("fastdds"),
                .linkedLibrary("fastcdr"),
                .linkedLibrary("BlocksRuntime")
            ]
        ),
        .target(
            name: "_FastDDSHelpers",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            swiftSettings: swiftSettings + [
                .unsafeFlags([
                    "-emit-clang-header-path", ".compatibility-headers/_FastDDSHelpers-Swift.h"
                ])
            ]
        )
        // .macro(
        //     name: "DDSKitMacros",
        //     dependencies: [
        //         .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        //         .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
        //     ]
        // )
    ],
    cxxLanguageStandard: .cxx14
)
