// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Onit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "Onit", targets: ["Onit"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.1")
    ],
    targets: [
        .target(
            name: "Onit",
            dependencies: ["SwiftSoup"]
        )
    ]
)