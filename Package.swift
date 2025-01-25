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

let cSettings: [CSetting] = [
    .unsafeFlags(["-I/home/hbaker/.local/share/swiftly/toolchains/6.0.3/usr/include/"])
]
let cxxSettings: [CXXSetting] = [
    .unsafeFlags(["-I/home/hbaker/.local/share/swiftly/toolchains/6.0.3/usr/include/"])
]
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
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "DDSKit",
            dependencies: [
                "DDSKitMacros",
                "_CFastDDS",
                "_FastDDSHelpers",
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
        ),
        .macro(
            name: "DDSKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        )
    ],
    cxxLanguageStandard: .cxx14
)
