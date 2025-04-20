/**
 * Package@swift-6.0.swift
 * DDSKit
 *
 * Created by Hunter Baker on 4/20/25
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .interoperabilityMode(.Cxx),
    .enableUpcomingFeature("InternalImportsByDefault")
]
var cfastddsLinkerSettings: [LinkerSetting] = []

#if canImport(Darwin)
    let applePlatformDependencies: [Package.Dependency] = [
        .package(url: "https://github.com/literally-anything/Fast-DDS-Prebuild.git", from: "3.0.0")
    ]
    let applePlatformTargetDependencies: [Target.Dependency] = [
        .product(
            name: "Fast-DDS", package: "Fast-DDS-Prebuild",
            condition: .when(platforms: [.macOS, .iOS, .visionOS])
        )
    ]
    cfastddsLinkerSettings.append(contentsOf: [
        .linkedFramework("CoreFoundation", .when(platforms: [.macOS, .iOS, .visionOS])),  // Used for the BlocksRuntime
        .linkedFramework("IOKit", .when(platforms: [.macOS, .iOS, .visionOS]))  // IOKit is used by FastDDS on macOS
    ])
#else
    let applePlatformDependencies: [Package.Dependency] = []
    let applePlatformTargetDependencies: [Target.Dependency] = []
    cfastddsLinkerSettings.append(contentsOf: [
        .linkedLibrary("fastdds"),
        .linkedLibrary("fastcdr"),
        .linkedLibrary("BlocksRuntime")
    ])
#endif


let package = Package(
    name: "DDSKit",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(
            name: "DDSKit",
            targets: ["DDSKit"]
        )
    ],
    dependencies: applePlatformDependencies + [
        .package(url: "https://github.com/apple/swift-syntax", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .macro(
            name: "DDSKitMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DDSKit",
            dependencies: [
                "DDSKitMacros",
                "_CFastDDS",
                .product(name: "Logging", package: "swift-log")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "_CFastDDS",
            dependencies: applePlatformTargetDependencies,
            linkerSettings: cfastddsLinkerSettings
        )
    ],
    cxxLanguageStandard: .cxx14
)
