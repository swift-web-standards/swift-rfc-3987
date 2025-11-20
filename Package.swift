// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-3987",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RFC 3987",
            targets: ["RFC 3987"]
        ),
        .library(
            name: "RFC 3987 Foundation",
            targets: ["RFC 3987 Foundation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "RFC 3987",
            dependencies: [
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986")
            ]
            // Core module - uses INCITS_4_1986 for ASCII validation, no Foundation
        ),
        .target(
            name: "RFC 3987 Foundation",
            dependencies: ["RFC 3987"]
            // Foundation extensions - depends on core
        ),
        .testTarget(
            name: "RFC 3987".tests,
            dependencies: ["RFC 3987", "RFC 3987 Foundation"]
        )
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
