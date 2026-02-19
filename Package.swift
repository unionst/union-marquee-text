// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "union-marquee-text",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UnionMarqueeText",
            targets: ["UnionMarqueeText"]
        ),
    ],
    targets: [
        .target(
            name: "UnionMarqueeText"
        ),

    ]
)
