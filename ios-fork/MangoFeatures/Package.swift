// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MangoFeatures",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "MangoFeatures", targets: ["MangoFeatures"])
    ],
    targets: [
        .target(name: "MangoFeatures"),
        .testTarget(name: "MangoFeaturesTests", dependencies: ["MangoFeatures"])
    ]
)
