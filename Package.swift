// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkService",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "NetworkService",
            targets: ["NetworkService"]),
    ],
    dependencies: [
           .package(url: "https://github.com/Moya/Moya.git", exact: "15.0.3")
    ],
    targets: [
        .target(
            name: "NetworkService",
            dependencies: [
                .product(name: "Moya", package: "Moya")
            ]
        )
    ]
)
