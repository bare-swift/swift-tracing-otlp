// swift-tools-version: 6.0
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import PackageDescription

let package = Package(
    name: "swift-tracing-otlp",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TracingOTLP", targets: ["TracingOTLP"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.4.0"),
        .package(url: "https://github.com/bare-swift/swift-bytes.git", from: "0.1.0"),
        .package(url: "https://github.com/bare-swift/swift-varint.git", from: "0.1.0"),
        .package(url: "https://github.com/bare-swift/swift-otlp-exporter.git", from: "0.1.0"),
        .package(url: "https://github.com/bare-swift/swift-time.git", from: "0.1.0"),
        .package(url: "https://github.com/bare-swift/swift-hex.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "TracingOTLP",
            dependencies: [
                .product(name: "Bytes", package: "swift-bytes"),
                .product(name: "Varint", package: "swift-varint"),
                .product(name: "OTLPExporter", package: "swift-otlp-exporter"),
                .product(name: "Time", package: "swift-time"),
                .product(name: "Hex", package: "swift-hex")
            ]
        ),
        .testTarget(
            name: "TracingOTLPTests",
            dependencies: ["TracingOTLP"],
            resources: [.copy("../Vectors")]
        )
    ]
)
